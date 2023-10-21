import subprocess
import json
import shlex
import traceback
import logging
import time
import sys
from concurrent.futures import ThreadPoolExecutor, wait
from typing import List, Dict, Any

PRINCIPAL_NAME = "cyngularSP"
RESOURCE_GROUP = "cyngularRG"
ACTIVITY_FILE = "activity-logs.bicep"
CYNGULAR_PUBLIC_KEY=".local/cyngularPublic.key"

LOG_SETTINGS = "\"[{category:AuditEvent,enabled:true,retention-policy:{enabled:false,days:30}}]\""
AUDIT_LOG_SETTINGS = "\"[{categoryGroup:audit,enabled:true,retention-policy:{enabled:false,days:30}},{categoryGroup:allLogs,enabled:true,retention-policy:{enabled:false,days:30}}]\""
NETWORK_SERCURITY_SETTINGS = "\"[{category:NetworkSecurityGroupEvent,enabled:true,retention-policy:{enabled:false,days:30}},{category:NetworkSecurityGroupRuleCounter,enabled:true,retention-policy:{enabled:false,days:30}}]\""
ALL_LOGS_SETTING = "\"[{categoryGroup:allLogs,enabled:true,retention-policy:{enabled:false,days:30}}]\""

logging.basicConfig(
    filename="CyngularOnboarding.log",
    filemode="a",
    format="%(asctime)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)

def cli(args, verbose=True):
    try:
        args = shlex.split(args)
        process = subprocess.Popen(
            args, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        out, err = process.communicate()
        exit_code = process.returncode
        if exit_code != 0:
            raise ValueError(str(err) + '  "' + ' in => ' + sys._getframe(1).f_code.co_name + "\n" + " ".join(args) + '"')

        return json.loads(out) if out else out
    except Exception:
        if("was not found" in traceback.format_exc()):
            return
        elif("does not support diagnostic settings" in traceback.format_exc()):
            return
        elif("could not be found" in traceback.format_exc()):
            return
        # elif("'AuditEvent' is not supported" in traceback.format_exc()):
        #     return
        error_message = traceback.format_exc()
        if verbose:
            logging.critical(error_message)
        raise Exception(error_message)

# Error Handling Wrapper
def handle_exception(func):
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception:
            logging.critical(f"{traceback.format_exc()}")
    return wrapper

@handle_exception
def add_account_extension():
    logging.info("Adding extension named account")
    print("Adding 'az account' extension")
    args = "az extension add --name account"
    acc_ext = cli(args)
    print(f"added acc ext: \n{acc_ext}\n")
    return acc_ext

@handle_exception
def import_public_key():
    logging.info("Importing public key")
    print("Importing public key")
    args = f"gpg --import {CYNGULAR_PUBLIC_KEY}"
    return cli(args)

@handle_exception
def delete_data_file(data_file_name):
    args = f"rm {data_file_name}"
    return cli(args)

@handle_exception
def encrypt_data(data_file_name):
    logging.info(f"Encrypting {data_file_name} file with public key")
    print(f"Encrypting {data_file_name} file with public key")
    args = f"gpg --encrypt --armor -r cyngularsecurity@gmail.com {data_file_name}"
    return cli(args)
    
@handle_exception
def get_subscription_lst():
    logging.info("Listing client subscription ids")
    print("Listing client subscription ids")
    args = "az account subscription list --query [].subscriptionId"
    sub_list = cli(args)
    print(f"found sunscriptions: \n{sub_list}\n")
    return sub_list

@handle_exception
def create_cyngular_service_principal():
    logging.info("Creating cyngular service principal")
    print("Creating cyngular service principal")
    args = f"az ad sp create-for-rbac --name {PRINCIPAL_NAME}"
    
    res = cli(args)
    principal_app_id = res["appId"]
    principal_password = res["password"]
    principal_tenant = res["tenant"]
    print(f"principle properties: \n{res}\n")
    return principal_app_id, principal_password, principal_tenant

@handle_exception
def set_subscription(subscription_id: str):
    args = f"az account set --subscription {subscription_id}"
    curr_sub = cli(args)
    print(f"current subscription: \n{curr_sub}\n")


@handle_exception
def get_principal_object_id(principal_app_id: str):
    args = f"az ad sp show --id {principal_app_id} --query id"
    principal_object_id = cli(args)
    print(f"principal object id: \n{principal_object_id}\n")
    return principal_object_id

@handle_exception
def assign_subscription_role(subscription_id: str, principal_object_id: str, role: str):
    args = (f'az role assignment create --assignee-object-id {principal_object_id} --assignee-principal-type ServicePrincipal --role "{role}" --scope /subscriptions/{subscription_id}')
    _ = cli(args)

@handle_exception
def create_resource_group_with_subscription(subscription: str, resource_group_location: str, resource_group_name: str):
    logging.info(f"Creating {resource_group_name} resource group in subscription - {subscription}")
    print(f"Creating {resource_group_name} resource group in subscription - {subscription}")
    args = (f"az group create -l {resource_group_location} -n {resource_group_name}-{resource_group_location} --subscription {subscription}")
    cli(args)

@handle_exception
def create_resource_group(resource_group_location: str, resource_group_name: str):
    logging.info(f"Creating {resource_group_name} resource group")
    print(f"Creating {resource_group_name} resource group")
    args = (f"az group create -l {resource_group_location} -n {resource_group_name}")
    cli(args)

@handle_exception
def create_audit_storage_account(audit_storage_account_name: str, company_region: str):
    logging.info("Creating audit storage account")
    print("Creating audit storage account")
    args = f"az storage account list --resource-group {RESOURCE_GROUP} --query \"[?name=='{audit_storage_account_name}'].id\""
    res = cli(args)
    # create new storage account if there is no audit storage account in  cyngular resource group
    if len(res) == 0:
        args = f"az storage account create -n {audit_storage_account_name} -g {RESOURCE_GROUP} -l {company_region} --sku Standard_LRS --default-action Allow --bypass Logging Metrics AzureServices"
        audit_storage_account_id = cli(args)["id"]
        return audit_storage_account_id

@handle_exception
def create_nsg_storage_account(nsg_storage_account_name: str, company_region: str):
    logging.info("Creating nsg storage account")
    print("Creating nsg storage account")
    args = f"az storage account list --resource-group {RESOURCE_GROUP} --query \"[?name=='{nsg_storage_account_name}'].id\""
    # create new storage account if there is no audit storage account in  cyngular resource group
    if len(cli(args)) == 0:
        args = f"az storage account create -n {nsg_storage_account_name} -g {RESOURCE_GROUP} -l {company_region} --sku Standard_LRS"
        nsg_storage_account_id = cli(args)["id"]
        return nsg_storage_account_id

@handle_exception
def get_storage_accounts_connection_string(audit_storage_account_name: str, nsg_storage_account_name: str):
    logging.info("Getting the storage accounts connection strings")
    args = f"az storage account show-connection-string -g {RESOURCE_GROUP} -n {audit_storage_account_name} --query connectionString"
    audit_connection_string = cli(args)
    args = f"az storage account show-connection-string -g {RESOURCE_GROUP} -n {nsg_storage_account_name} --query connectionString"
    nsg_connection_string = cli(args)
    return audit_connection_string, nsg_connection_string

@handle_exception
def export_activity_logs(subscription: str, audit_storage_account_id: str, company_region: str):
    logging.info(f"Exporting activity logs from subscription: {subscription}")
    print(f"Exporting activity logs from subscription: {subscription}")
    args = f"az deployment sub create --location {company_region} --template-file {ACTIVITY_FILE} --parameters settingName=cyngularDiagnostic storageAccountId={audit_storage_account_id} --subscription {subscription}"
    _ = cli(args)

@handle_exception
def import_diagnostic_settings(resource: str, audit_storage_account_id: str):
    if("storageAccounts" in resource or "virtualMachines" in resource or "networkInterfaces" in resource or "disks" in resource or "virtualNetworks" in resource or "sshPublicKeys" in resource or "serverFarms" in resource or "sites" in resource):
        return
    if("flexibleServers" in resource or "publicIPAddresses" in resource or "vaults" in resource or "namespaces" in resource or "workspaces" in resource):
        args = f"az monitor diagnostic-settings create --name CyngularDiagnostic --resource {resource} --storage-account {audit_storage_account_id} --logs {AUDIT_LOG_SETTINGS}"
    elif("networkSecurityGroups" in resource or "bastionHosts" in resource or "components" in resource):
        args = f"az monitor diagnostic-settings create --name CyngularDiagnostic --resource {resource} --storage-account {audit_storage_account_id} --logs {ALL_LOGS_SETTING}"
    else:
        args = f"az monitor diagnostic-settings create --name CyngularDiagnostic --resource {resource} --storage-account {audit_storage_account_id} --logs {LOG_SETTINGS}"
    _ = cli(args)

@handle_exception
def get_resource_groups(subscription: str) -> List[Dict[str, Any]]:
    args = f"az group list --subscription {subscription}"
    res = cli(args)
    return [{"name": group["name"], "id": group["id"], "location": group["location"]} for group in res]

@handle_exception
def get_network_interfaces(subscription_resource_group: str, subscription: str):
    logging.info(f"Collecting nsg flow logs from resource group: {subscription_resource_group}")
    print(f"Collecting nsg flow logs from resource group: {subscription_resource_group}")
        
    args = f"az network nsg list --resource-group {subscription_resource_group} --subscription {subscription}"
    res = cli(args)
    return [{"id": nsg["id"], "location": nsg["location"]} for nsg in res]

@handle_exception
def is_network_watcher_in_location(subscription: str, location: str) -> bool:
    args = f"az network watcher list --query \"[?location=='{location}'].id\" --subscription {subscription}"
    return not bool(cli(args))
    # return cli(args) is None

# @handle_exception
def network_watcher_configure(subscription: str, location: str):
    try:
        args = f"az network watcher configure -g NetworkWatcherRG -l {location} --subscription {subscription} --enabled true"
        cli(args)
    except Exception as e:
        if "NetworkWatcherCountLimitReached" not in str(e):
            logging.critical(f"{traceback.format_exc()}")

@handle_exception
def create_nsg_flowlog(location: str, network_interface_id: str, nsg_storage_account_id: str, subscription: str):
    args = f"az network watcher flow-log create --name cyngular --nsg {network_interface_id} --storage-account {nsg_storage_account_id} --location {location} --subscription {subscription}"
    cli(args)

@handle_exception
def configure_and_create_nsg_flowlog(subscription, network_interface ,company_region ,nsg_storage_account_id):
    # configurating network watcher on network interface location
    if (is_network_watcher_in_location(subscription, network_interface["location"])== False):
        network_watcher_configure(subscription, network_interface["location"])
    # creating nsg flow log
    if network_interface["location"] == company_region:
       create_nsg_flowlog(network_interface["location"], network_interface["id"], nsg_storage_account_id, subscription)


@handle_exception
def create_network_integration(subscription: str, subscription_resource_group: Dict[str, Any], nsg_storage_account_id: str, company_region: str):
    network_interface_lst = get_network_interfaces(subscription_resource_group["name"], subscription)
    if not is_network_watcher_in_location(subscription, subscription_resource_group["location"]):
        network_watcher_configure(subscription, subscription_resource_group["location"])

    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = [
            executor.submit(configure_and_create_nsg_flowlog, subscription, network_interface, company_region, nsg_storage_account_id)
            for network_interface in network_interface_lst
        ]
        wait(futures)

# @handle_exception
def subscription_manager(company_region, subscription, principal_object_id, audit_storage_account_id, nsg_storage_account_id):
    try:
        logging.info(f"The current subscription is: {subscription}")
        print(f"The current subscription is: {subscription}")

        # assigning cyngular service princicpal the required roles in the
        assign_subscription_role(subscription, principal_object_id, "Reader")
        assign_subscription_role(
            subscription, principal_object_id, "Disk Pool Operator"
        )
        assign_subscription_role(
            subscription, principal_object_id, "Data Operator for Managed Disks"
        )
        assign_subscription_role(
            subscription, principal_object_id, "Disk Snapshot Contributor"
        )
        assign_subscription_role(
            subscription, principal_object_id, "Microsoft Sentinel Reader"
        )

        # exporting activity logs from the subscription
        export_activity_logs(subscription, audit_storage_account_id, company_region)
        
        # create network watcher resource group
        create_resource_group_with_subscription(subscription, company_region, "NetworkWatcherRG")

        # getting the subscription resource group
        resource_groups = get_resource_groups(subscription)
        future = []
        with ThreadPoolExecutor(max_workers=10) as executor:
            for subscription_resource_group in resource_groups:
                future.append(executor.submit(create_network_integration, subscription, subscription_resource_group, nsg_storage_account_id, company_region))
            _ = wait(future)    
        #importing diagnostic settings for the resource
        logging.info("Importing diagnostic settings")
        print("Importing diagnostic settings")
        resource_ids_cli = f"az resource list --location {company_region} --query \"[].id\" --subscription {subscription}"
        resource_ids = cli(resource_ids_cli)
        resource = ""
        future = []
        with ThreadPoolExecutor(max_workers=10) as executor:
            for resource in resource_ids:
                 future.append(executor.submit(import_diagnostic_settings, resource ,audit_storage_account_id))
            _ = wait(future)
    except Exception:
        logging.critical(f"{traceback.format_exc()}")

@handle_exception
def main():
    try:
        logging.info("STARTING CYNGULAR ONBOARING PROCESS")
        print(" STARTING CYNGULAR ONBOARING PROCESS")
        print("=====================================\n")

        location_lst= ["eastasia","southeastasia","australiaeast","australiasoutheast","brazilsouth","canadacentral","canadaeast","switzerlandnorth","germanywestcentral","eastus2","eastus","centralus","northcentralus","francecentral","uksouth","ukwest","centralindia","southindia","jioindiawest","japaneast","japanwest","koreacentral","northeurope","norwayeast","swedencentral","uaenorth","westcentralus","westeurope","westus2","westus","southcentralus","westus3","southafricanorth","australiacentral","australiacentral2","westindia","koreasouth","polandcentral","qatarcentral","eastusstg","centraluseuap","eastus2euap","southcentralusstg"]
        company_region = input("Please enter your company main region here: ")
        while(company_region not in location_lst):
            company_region = input("\n*Invalid region to see all the available regions type in cloud shell:\n \"az account list-locations --output table\"\nPlease Re-Enter Your Company Main Region Here: ")

        company_name = input("Please enter your company name here: ")
        nsg_storage_account_name = "cyngularnsg" + company_name + company_region
        while(len(company_name) > 24 or len(company_name + company_region) > 24 or len("cyngularaudit" + company_name) > 24 or len(nsg_storage_account_name) > 24):
            if(len("cyngularnsg" + company_name + company_region) > 24):
                nsg_storage_account_name = "cyngularnsg" + company_name + company_region[0:3]
                if(len(nsg_storage_account_name) > 24):
                    company_name = input("\n*Your company name is too long\nPlease re-Enter your company name here: ")

        audit_storage_account_name = "cyngularaudit" + company_name
        t0 = time.time()
        
        # adding extension library named account
        add_account_extension()

        # getting the client subscription ids
        subscriptions_lst = get_subscription_lst()

        # creating cyngular's service principal
        (
            principal_app_id,
            principal_password,
            principal_tenant,
        ) = create_cyngular_service_principal()
        principal_object_id = get_principal_object_id(principal_app_id)

        # creating cyngular's storage accounts resource group
        create_resource_group(company_region, RESOURCE_GROUP)

        # creating cyngular storage accounts
        audit_storage_account_id = create_audit_storage_account(audit_storage_account_name, company_region)
        nsg_storage_account_id = create_nsg_storage_account(nsg_storage_account_name, company_region)
        (
            audit_connection_string,
            nsg_connection_string,
        ) = get_storage_accounts_connection_string(audit_storage_account_name, nsg_storage_account_name)

        # creating thread pool in subscriptions iteration
        with ThreadPoolExecutor(max_workers=10) as executor:
            for subscription in subscriptions_lst:
                executor.submit(subscription_manager, company_region, subscription, principal_object_id, audit_storage_account_id, nsg_storage_account_id)        
        
        logging.info("FINISHED ONBOARDING")
        print("FINISHED ONBOARDING")
        data_file_name = f"{company_name}_data.txt"
        with open(data_file_name, "a") as file:
            file.write(f"Service Principal App ID: {principal_app_id}\n")
            file.write(f"Service Principal Password: {principal_password}\n")
            file.write(f"Service Principal Tenant: {principal_tenant}\n")
            file.write(f"Service Principal Audit Storage Account Connection String: {audit_connection_string}\n")
            file.write(f"Service Principal NSG Storage Account Connection String: {nsg_connection_string}\n")
        import_public_key()
        encrypt_data(data_file_name)
        #delete_data_file(data_file_name)

        print("ON-BOARDING FINISHED")
        t1 = time.time()
        print(f"onbooarding took:\t {t1-t0} sec")
    except Exception:
        logging.critical(f"{traceback.format_exc()}")

if __name__ == "__main__":
    main()


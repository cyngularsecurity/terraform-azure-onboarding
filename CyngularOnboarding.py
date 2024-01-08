from concurrent.futures import ThreadPoolExecutor, wait
from typing import List, Dict, Any
import subprocess
import traceback
import time
import sys
import logging
import shlex
import json

CLIENT_NAME = "gibson"
PRINCIPAL_NAME = f"CyngularSP-{CLIENT_NAME}"
RESOURCE_GROUP = f"CyngularRG-{CLIENT_NAME}"
RESOURCE_GROUP_LOCATION = "westus"
AUDIT_STORAGE_ACCOUNT_NAME = f"cyngularaudit{CLIENT_NAME}"
NSG_STORAGE_ACCOUNT_NAME = f"cyngularnsg{CLIENT_NAME}"
ACTIVITY_FILE_NAME = "activity-logs.bicep"

CYNGULAR_PUBLIC_KEY=".local/cyngularPublic.key"

blue = "\033[1;34m"
red = "\033[1;91m"
magenta = "\033[1;35m"
green = "\033[1;92m"
white = "\x1b[0m"

logging.basicConfig(
    filename="CyngularOnboarding.log",
    filemode="a",
    format="%(asctime)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)

AUDIT_AND_ALL_LOG_SETTINGS = "\"[{categoryGroup:audit,enabled:true,retention-policy:{enabled:false,days:30}},{categoryGroup:allLogs,enabled:true,retention-policy:{enabled:false,days:30}}]\""
AUDIT_EVENT_LOG_SETTINGS = "\"[{category:AuditEvent,enabled:true,retention-policy:{enabled:false,days:30}}]\""
ALL_LOGS_SETTING = "\"[{categoryGroup:allLogs,enabled:true,retention-policy:{enabled:false,days:30}}]\""
# NETWORK_SERCURITY_SETTINGS = "\"[{category:NetworkSecurityGroupEvent,enabled:true,retention-policy:{enabled:false,days:30}},{category:NetworkSecurityGroupRuleCounter,enabled:true,retention-policy:{enabled:false,days:30}}]\""

def cli(args, verbose=True):
    try:
        args = shlex.split(args)
        process = subprocess.Popen(
            args, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        # if wait:
        #     process.wait()
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
        elif("'AuditEvent' is not supported" in traceback.format_exc()):
            return
        error_msg = traceback.format_exc()
        if verbose:
            logging.critical(error_msg)
        raise Exception(error_msg)

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
    _ = cli(args)

@handle_exception
def import_public_key():
    logging.info("Importing public key")
    print("Importing public key")
    args = f"gpg  --trust-model always --import {CYNGULAR_PUBLIC_KEY}"
    return cli(args)

@handle_exception
def delete_data_file(data_file_name):
    args = f"rm {data_file_name}"
    return cli(args)

@handle_exception
def encrypt_data(data_file_name):
    logging.info(f"Encrypting {data_file_name} file with public key")
    print(f"Encrypting {data_file_name} file with public key")
    # args = f"gpg --encrypt --armor -r cyngularsecurity@gmail.com {data_file_name}"
    args = f"gpg --trust-model always --encrypt --armor -r cyngularsecurity@gmail.com {data_file_name}"
    return cli(args)
    
@handle_exception
def get_subscription_lst():
    logging.info("Listing client subscription ids")
    print("Listing client subscription ids")
    args = "az account subscription list --query [].subscriptionId"
    sub_list = cli(args)
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
    return principal_app_id, principal_password, principal_tenant

@handle_exception
def set_subscription(subscription_id: str):
    args = f"az account set --subscription {subscription_id}"
    _ = cli(args)

@handle_exception
def get_principal_object_id(principal_app_id: str):
    args = f"az ad sp show --id {principal_app_id} --query id"
    principal_object_id = cli(args)
    return principal_object_id

@handle_exception
def assign_subscription_role(subscription_id: str, principal_object_id: str, role: str):
    args = (f"az role assignment create --assignee-object-id {principal_object_id} --assignee-principal-type ServicePrincipal --role \"{role}\" --scope /subscriptions/{subscription_id}")
    cli(args)

@handle_exception
def create_resource_group_with_subscription(subscription: str, resource_group_location: str, resource_group_name: str):
    logging.info(f"Creating {resource_group_name} resource group in subscription - {subscription}")
    print(f"Creating {resource_group_name} resource group in subscription - {subscription}")
    args = (f"az group create -l {resource_group_location} -n {resource_group_name} --subscription {subscription}")
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
    if len(res) == 0:
        args = f"az storage account create -n {audit_storage_account_name} -g {RESOURCE_GROUP} -l {company_region} --sku Standard_LRS --default-action Allow --bypass Logging Metrics AzureServices"
        audit_storage_account_id = cli(args)["id"]
        return audit_storage_account_id

@handle_exception
def create_nsg_storage_account(nsg_storage_account_name: str, company_region: str):
    logging.info("Creating nsg storage account")
    print("Creating nsg storage account")
    args = f"az storage account list --resource-group {RESOURCE_GROUP} --query \"[?name=='{nsg_storage_account_name}'].id\""
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
    args = f"az deployment sub create --name {CLIENT_NAME}-ActivityLogs --location {company_region} --template-file {ACTIVITY_FILE_NAME} --parameters settingName=cyngularDiagnostic storageAccountId={audit_storage_account_id} --subscription {subscription}"
    cli(args)

@handle_exception
def export_diagnostic_settings(resource: str, audit_storage_account_id: str):
    if any(r in resource for r in ["storageAccounts", "virtualMachines", "networkInterfaces", "disks", "virtualNetworks", "sshPublicKeys", "serverFarms", "sites", "networkwatchers", "snapshots"]):
        return # since r does not support diagnostic settings
    if("flexibleServers" in resource or "publicIPAddresses" in resource or "vaults" in resource or "namespaces" in resource or "workspaces" in resource):
        args = f"az monitor diagnostic-settings create --name CyngularDiagnostic --resource {resource} --storage-account {audit_storage_account_id} --logs {AUDIT_AND_ALL_LOG_SETTINGS}"
    elif("networkSecurityGroups" in resource or "bastionHosts" in resource or "components" in resource):
        args = f"az monitor diagnostic-settings create --name CyngularDiagnostic --resource {resource} --storage-account {audit_storage_account_id} --logs {ALL_LOGS_SETTING}"
    else:
        args = f"az monitor diagnostic-settings create --name CyngularDiagnostic --resource {resource} --storage-account {audit_storage_account_id} --logs {AUDIT_EVENT_LOG_SETTINGS}"
    cli(args)

@handle_exception
def get_resource_groups(subscription: str) -> List[Dict[str, Any]]:
    args = f"az group list --subscription {subscription}"
    res = cli(args)
    return [{"name": group["name"], "id": group["id"], "location": group["location"]} for group in res]

@handle_exception
def get_network_interfaces(subscription_resource_group: str, subscription: str):
    logging.info(f"Checking nsg flow logs for resource group: {subscription_resource_group}| in subscription: {subscription}")
    print(f"Checking nsg flow logs for resource group: {subscription_resource_group}| in subscription: {subscription}")

    args = f"az network nsg list --resource-group {subscription_resource_group} --subscription {subscription}"
    res = cli(args)
    return [{"id": nsg["id"], "location": nsg["location"]} for nsg in res]

@handle_exception
def is_network_watcher_in_location(subscription: str, location: str) -> bool:
    args = f"az network watcher list --query \"[?location=='{location}'].id\" --subscription {subscription}"
    if cli(args) is None:
        return True
    return False

def network_watcher_configure(subscription: str, location: str, net_watch_rg: str):
    try:
        args = f"az network watcher configure -g {net_watch_rg} -l {location} --enabled true --subscription {subscription}"
        cli(args)
    except Exception as e:
        if "NetworkWatcherCountLimitReached" not in str(e):
            logging.critical(f"{traceback.format_exc()}")

@handle_exception
def create_nsg_flowlog(location: str, network_interface_id: str, nsg_storage_account_id: str, subscription: str):
    args = f"az network watcher flow-log create --location {location} --name cyngular --nsg {network_interface_id} --storage-account {nsg_storage_account_id} --subscription {subscription}"
    cli(args)

@handle_exception
def configure_and_create_nsg_flowlog(subscription, network_interface ,company_region ,nsg_storage_account_id, net_watch_rg: str):
    # configurating network watcher on network interface location
    if  not is_network_watcher_in_location(subscription, network_interface["location"]):
        network_watcher_configure(subscription, network_interface["location"], net_watch_rg)
    # creating nsg flow log
    if network_interface["location"] == company_region:
       create_nsg_flowlog(network_interface["location"], network_interface["id"], nsg_storage_account_id, subscription)

@handle_exception
def create_network_integration(subscription: str, subscription_resource_group: Dict[str, Any], nsg_storage_account_id: str, company_region: str, net_watch_rg: str):
    network_interface_lst = get_network_interfaces(subscription_resource_group["name"], subscription)
    if not is_network_watcher_in_location(subscription, subscription_resource_group["location"]):
        network_watcher_configure(subscription, subscription_resource_group["location"], net_watch_rg)

    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = [
            executor.submit(configure_and_create_nsg_flowlog, subscription, network_interface, company_region, nsg_storage_account_id, net_watch_rg)
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
        assign_subscription_role(subscription, principal_object_id, "Disk Pool Operator")
        assign_subscription_role(subscription, principal_object_id, "Data Operator for Managed Disks")
        assign_subscription_role(subscription, principal_object_id, "Disk Snapshot Contributor")
        assign_subscription_role(subscription, principal_object_id, "Microsoft Sentinel Reader")

        # exporting activity logs from the subscription
        export_activity_logs(subscription, audit_storage_account_id, company_region)

        net_watch_rg = f"CyngularNetWatcherRG-{CLIENT_NAME}"
        # create network watcher resource group
        create_resource_group_with_subscription(subscription, company_region, net_watch_rg)

        # getting the subscription resource group
        resource_groups = get_resource_groups(subscription)
        future = []
        with ThreadPoolExecutor(max_workers=10) as executor:
            for subscription_resource_group in resource_groups:
                future.append(executor.submit(create_network_integration, subscription, subscription_resource_group, nsg_storage_account_id, company_region, net_watch_rg))
            _ = wait(future)
        #exporting diagnostic settings for the resource
        logging.info("Importing diagnostic settings")
        print("Importing diagnostic settings")
        resource_ids_cli = f"az resource list --location {company_region} --query \"[].id\" --subscription {subscription}"
        resource_ids = cli(resource_ids_cli)
        resource = ""
        future = []
        with ThreadPoolExecutor(max_workers=10) as executor:
            for resource in resource_ids:
                 future.append(executor.submit(export_diagnostic_settings, resource ,audit_storage_account_id))
            _ = wait(future)
    except Exception:
        logging.critical(f"{traceback.format_exc()}")

@handle_exception
def main():
    print(
        magenta
        + """
           ______                        __              _____                      _ __       
          / ____/_  ______  ____ ___  __/ /___ ______   / ___/___  _______  _______(_) /___  __
         / /   / / / / __ \/ __ `/ / / / / __ `/ ___/   \__ \/ _ \/ ___/ / / / ___/ / __/ / / /
        / /___/ /_/ / / / / /_/ / /_/ / / /_/ / /      ___/ /  __/ /__/ /_/ / /  / / /_/ /_/ / 
        \____/\__, /_/ /_/\__, /\__,_/_/\__,_/_/      /____/\___/\___/\__,_/_/  /_/\__/\__, /  
             /____/      /____/                                                       /____/

        """
        + white
    )
    print("\n")
    logging.info(" STARTING CYNGULAR ONBOARING PROCESS")
    print(f" {green}STARTING CYNGULAR ONBOARING PROCESS{white}")
    print("=====================================\n")
    location_lst= ["eastasia","southeastasia","australiaeast","australiasoutheast","brazilsouth","canadacentral","canadaeast","switzerlandnorth","germanywestcentral","eastus2","eastus","centralus","northcentralus","francecentral","uksouth","ukwest","centralindia","southindia","jioindiawest","japaneast","japanwest","koreacentral","northeurope","norwayeast","swedencentral","uaenorth","westcentralus","westeurope","westus2","westus","southcentralus","westus3","southafricanorth","australiacentral","australiacentral2","westindia","koreasouth","polandcentral","qatarcentral","eastusstg","centraluseuap","eastus2euap","southcentralusstg"]
    company_region = input(f"{blue}Please enter your company main region here: {white}")
    while company_region not in location_lst:
        company_region = input(f"{red}\n*Invalid region - {blue}to see all the available regions type in cloud shell:\n {green}'az account list-locations --output table'{blue}\nPlease Re-Enter Your Company Main Region Here: {white}")
    CLIENT_NAME = input(f"{blue}Please enter your company name here: {white}")
    nsg_storage_account_name = "cyngularnsg" + CLIENT_NAME + company_region
    while(len(CLIENT_NAME) > 24 or len(CLIENT_NAME + company_region) > 24 or len("cyngularaudit" + CLIENT_NAME) > 24 or len(nsg_storage_account_name) > 24):
        if(len("cyngularnsg" + CLIENT_NAME + company_region) > 24):
            nsg_storage_account_name = "cyngularnsg" + CLIENT_NAME + company_region[0:3]
            if(len(nsg_storage_account_name) > 24):
                CLIENT_NAME = input(f"{red}\n*Company name is too long{blue}\nPlease re-Enter your company name here: {white}")
    audit_storage_account_name = "cyngularaudit" + CLIENT_NAME 
    t0 = time.time()
    
    # add_account_extension()
    (
        principal_app_id,
        principal_password,
        principal_tenant,
    ) = create_cyngular_service_principal()
    
    principal_object_id = get_principal_object_id(principal_app_id)
    # creating cyngular's storage accounts resource group
    create_resource_group(company_region, RESOURCE_GROUP)
    
    audit_storage_account_id = create_audit_storage_account(audit_storage_account_name, company_region)
    nsg_storage_account_id = create_nsg_storage_account(nsg_storage_account_name, company_region)
    
    (
        audit_connection_string,
        nsg_connection_string,
    ) = get_storage_accounts_connection_string(audit_storage_account_name, nsg_storage_account_name)

    subscriptions_lst = get_subscription_lst()
    with ThreadPoolExecutor(max_workers=10) as executor:
        for subscription in subscriptions_lst:
            executor.submit(subscription_manager, company_region, subscription, principal_object_id, audit_storage_account_id, nsg_storage_account_id)        
    
    logging.info("FINISHED ONBOARDING")
    print("FINISHED ONBOARDING")
    data_file_name = f".local/{CLIENT_NAME}_data.txt"
    with open(data_file_name, "a") as file:
        file.write(f"Service Principal App ID: {principal_app_id}\n")
        file.write(f"Service Principal Password: {principal_password}\n")
        file.write(f"Service Principal Tenant: {principal_tenant}\n")
        file.write(f"Audit Storage Account Connection String: {audit_connection_string}\n")
        file.write(f"NSG Storage Account Connection String: {nsg_connection_string}\n")
    # import_public_key()
    # encrypt_data(data_file_name)
    #delete_data_file(data_file_name)

    print("ON-BOARDING FINISHED")
    t1 = time.time()
    print(f"onbooarding took:\t {t1-t0} sec")

if __name__ == "__main__":
    main()
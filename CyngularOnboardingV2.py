import subprocess
import json
import shlex
import traceback
import logging
import time
from concurrent.futures import ThreadPoolExecutor
from concurrent.futures import wait

PRINCIPAL_NAME = "cyngularSP"
CLIENT_NAME = "xxxxxxxxxx"
RESOURCE_GROUP = "cyngularRG"
RESOURCE_GROUP_LOCATION = "xxxxxxxxxx"
AUDIT_STORAGE_ACCOUNT_NAME = f"cyngularaudit{CLIENT_NAME}"
NSG_STORAGE_ACCOUNT_NAME = f"cyngularnsg{CLIENT_NAME}xxxxxxxxxx"
ACTIVITY_FILE_NAME = "activity-log.bicep"

LOG_SETTINGS = "\"[{category:AuditEvent,enabled:true,retention-policy:{enabled:false,days:30}}]\""
AUDIT_LOG_SETTINGS = "\"[{categoryGroup:audit,enabled:true,retention-policy:{enabled:false,days:30}},{categoryGroup:allLogs,enabled:true,retention-policy:{enabled:false,days:30}}]\""
NETWORK_SERCURITY_SETTINGS = "\"[{category:NetworkSecurityGroupEvent,enabled:true,retention-policy:{enabled:false,days:30}},{category:NetworkSecurityGroupRuleCounter,enabled:true,retention-policy:{enabled:false,days:30}}]\""
ALLLOGS_SETTING = "\"[{categoryGroup:allLogs,enabled:true,retention-policy:{enabled:false,days:30}}]\""
logging.basicConfig(
    filename="cyngular_onboarding.log",
    filemode="a",
    format="%(asctime)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)

def azcli(cli_args, verbose=True):
    try:
        cli_args = shlex.split(cli_args)
        process = subprocess.Popen(
            cli_args, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        out, err = process.communicate()
        exit_code = process.returncode
        if exit_code and exit_code != 0:
            raise ValueError(str(err) + '  "' + " ".join(cli_args) + '"')
        elif len(out) == 0:
            return out
        else:
            return json.loads(out)
    except Exception:
        if("was not found" in traceback.format_exc()):
            return
        elif("does not support diagnostic settings" in traceback.format_exc()):
            return
        elif("could not be found" in traceback.format_exc()):
            return
        elif("'AuditEvent' is not supported" in traceback.format_exc()):
            return
        if verbose:
            logging.critical(traceback.format_exc())
        else:
            raise Exception(traceback.format_exc())

def add_account_extension():
    try:
        logging.info("Adding extension named account")
        print("Adding extension named account")

        cli_args = f"az extension add --name account"
        return azcli(cli_args)
    except Exception as e:
        raise Exception(str(e))
    

def import_public_key():
    try:
        logging.info("Importing public key")
        print("Importing public key")

        cli_args = f"gpg --import cyngular_public.key"
        return azcli(cli_args)
    except Exception as e:
        raise Exception(str(e))


def delete_data_file(data_file_name):
    try:
        cli_args = f"rm {data_file_name}"
        return azcli(cli_args)
    except Exception as e:
        raise Exception(str(e))
    

def encrypt_data(data_file_name):
    try:
        logging.info(f"Encrypting {data_file_name} file with public key")
        print(f"Encrypting {data_file_name} file with public key")

        cli_args = f"gpg --encrypt --armor -r cyngularsecurity@gmail.com {data_file_name}"
        return azcli(cli_args)
    except Exception as e:
        raise Exception(str(e))
    
    
def get_subscription_lst():
    try:
        logging.info("Collecting client subscriptions id")
        print("Collecting client subscriptions id")

        cli_args = f"az account subscription list --query [].subscriptionId"
        return azcli(cli_args)
    except Exception as e:
        raise Exception(str(e))


def create_cyngular_service_principal():
    try:
        logging.info("Creating cyngular service principal")
        print("Creating cyngular service principal")
        cli_args = f"az ad sp create-for-rbac --name {PRINCIPAL_NAME}"
        res = azcli(cli_args)
        principal_app_id = res["appId"]
        principal_password = res["password"]
        principal_tenant = res["tenant"]

        return principal_app_id, principal_password, principal_tenant
    except Exception as e:
        raise Exception(str(e))


def set_subscription(subscription_id: str):
    try:
        cli_args = f"az account set --subscription {subscription_id}"
        res = azcli(cli_args)
    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")


def get_principal_object_id(principal_app_id: str):
    try:
        cli_args = f"az ad sp show --id {principal_app_id} --query id"
        principal_object_id = azcli(cli_args)
        return principal_object_id
    except Exception as e:
        raise Exception(str(e))


def assign_subscription_role(subscription_id: str, principal_object_id: str, role: str):
    try:
        cli_args = f'az role assignment create --assignee-object-id {principal_object_id} --assignee-principal-type ServicePrincipal --role "{role}" --scope /subscriptions/{subscription_id}'
        res = azcli(cli_args)
    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")


def create_resource_group_with_subscription(subscription: str, resource_group_location: str, resource_group_name: str):
    try:
        logging.info(f"Creating {resource_group_name} resource group using subscription")
        print(f"Creating {resource_group_name} resource group using subscription")
        cli_args = (
            f"az group create -l {resource_group_location} -n {resource_group_name} --subscription {subscription}"
        )
        azcli(cli_args)
    except Exception as e:
        if resource_group_name == RESOURCE_GROUP:
            raise Exception(str(e))
        else:
            logging.critical(f"{traceback.format_exc()}")

def create_resource_group(resource_group_location: str, resource_group_name: str):
    try:
        logging.info(f"Creating {resource_group_name} resource group")
        print(f"Creating {resource_group_name} resource group")
        cli_args = (
            f"az group create -l {resource_group_location} -n {resource_group_name}"
        )
        azcli(cli_args)
    except Exception as e:
        if resource_group_name == RESOURCE_GROUP:
            raise Exception(str(e))
        else:
            logging.critical(f"{traceback.format_exc()}")


def create_audit_storage_account(audit_storage_account_name: str, company_region: str):
    try:
        logging.info("Creating audit storage account")
        print("Creating audit storage account")
        cli_args = f"az storage account list --resource-group {RESOURCE_GROUP} --query \"[?name=='{audit_storage_account_name}'].id\""
        res = azcli(cli_args)
        # create new storage account if there is no audit storage account in  cyngular resource group
        if len(res) == 0:
            cli_args = f"az storage account create -n {audit_storage_account_name} -g {RESOURCE_GROUP} -l {company_region} --sku Standard_LRS --default-action Allow --bypass Logging Metrics AzureServices"
            audit_storage_account_id = azcli(cli_args)["id"]
            return audit_storage_account_id

    except Exception as e:
        raise Exception(str(e))


def create_nsg_storage_account(nsg_storage_account_name: str, company_region: str):
    try:
        
        logging.info("Creating nsg storage account")
        print("Creating nsg storage account")
        cli_args = f"az storage account list --resource-group {RESOURCE_GROUP} --query \"[?name=='{nsg_storage_account_name}'].id\""
        # create new storage account if there is no audit storage account in  cyngular resource group
        if len(azcli(cli_args)) == 0:
            cli_args = f"az storage account create -n {nsg_storage_account_name} -g {RESOURCE_GROUP} -l {company_region} --sku Standard_LRS"
            nsg_storage_account_id = azcli(cli_args)["id"]
            return nsg_storage_account_id
    except Exception as e:
        raise Exception(str(e))


def get_storage_accounts_connection_string(audit_storage_account_name: str, nsg_storage_account_name: str):
    try:
        logging.info("Getting the storage accounts connection strings")
        cli_args = f"az storage account show-connection-string -g {RESOURCE_GROUP} -n {audit_storage_account_name} --query connectionString"
        audit_connection_string = azcli(cli_args)
        cli_args = f"az storage account show-connection-string -g {RESOURCE_GROUP} -n {nsg_storage_account_name} --query connectionString"
        nsg_connection_string = azcli(cli_args)
        return audit_connection_string, nsg_connection_string
    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")


def export_activity_logs(subscription: str, audit_storage_account_id: str, company_region: str):
    try:
        logging.info(f"Exporting activity logs from subscription: {subscription}")
        print(f"Exporting activity logs from subscription: {subscription}")
        cli_args = f"az deployment sub create --location {company_region} --template-file {ACTIVITY_FILE_NAME}  --parameters settingName=cyngularDiagnostic storageAccountId={audit_storage_account_id} --subscription {subscription}"
        audit_connection_string = azcli(cli_args)
    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")

def import_diagnostic_settings(resource: str, audit_storage_account_id: str):
    try:
        if("storageAccounts" in resource or "virtualMachines" in resource or "networkInterfaces" in resource or "disks" in resource or "virtualNetworks" in resource or "sshPublicKeys" in resource or "serverFarms" in resource or "sites" in resource):
            return
        if("flexibleServers" in resource or "publicIPAddresses" in resource or "vaults" in resource or "namespaces" in resource or "workspaces" in resource):
            cli_args = f"az monitor diagnostic-settings create --name cyngularDiagnostic --resource {resource} --storage-account {audit_storage_account_id} --logs {AUDIT_LOG_SETTINGS}"
        elif("networkSecurityGroups" in resource or "bastionHosts" in resource or "components" in resource):
            cli_args = f"az monitor diagnostic-settings create --name cyngularDiagnostic --resource {resource} --storage-account {audit_storage_account_id} --logs {ALLLOGS_SETTING}"
        else:
            cli_args = f"az monitor diagnostic-settings create --name cyngularDiagnostic --resource {resource} --storage-account {audit_storage_account_id} --logs {LOG_SETTINGS}"
        audit_connection_string = azcli(cli_args)
    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")

def get_resource_groups(subscription: str):
    try:
        cli_args = f"az group list --subscription {subscription}"
        res = azcli(cli_args)

        resource_groups = []
        for group in res:
            resource_group = {
                "name": group["name"],
                "id": group["id"],
                "location": group["location"],
            }
            resource_groups.append(resource_group)
        return resource_groups
    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")


def get_network_interfaces(subscription_resource_group: str, subscription: str):
    try:
        logging.info(
            f"Collecting nsg flow logs from resource group: {subscription_resource_group}"
        )
        print(
            f"Collecting nsg flow logs from resource group: {subscription_resource_group}"
        )

        cli_args = f"az network nsg list --resource-group {subscription_resource_group} --subscription {subscription}"
        res = azcli(cli_args)

        network_interfaces_lst = []
        if res:
            for nsg in res:
                network_interface = {"id": nsg["id"], "location": nsg["location"]}
                network_interfaces_lst.append(network_interface)
        return network_interfaces_lst

    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")


def is_network_watcher_in_location(subscription: str, location: str):
    try:
        cli_args = f"az network watcher list --query \"[?location=='{location}'].id\" --subscription {subscription}"
        if azcli(cli_args) == None:
            return True
        return False
    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")


def network_watcher_configure(subscription: str, location: str):
    try:
        cli_args = f"az network watcher configure -g NetworkWatcherRG  -l {location} --enabled true --subscription {subscription}"
        azcli(cli_args)
    except Exception as e:
        if "NetworkWatcherCountLimitReached" not in str(e):
            logging.critical(f"{traceback.format_exc()}")


def create_nsg_flowlog(location: str, network_interface_id: str, nsg_storage_account_id: str, subscription: str):
    try:
        cli_args = f"az network watcher flow-log create --location {location} --name cyngular --nsg {network_interface_id} --storage-account {nsg_storage_account_id} --subscription {subscription}"
        azcli(cli_args)
    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")

def configure_and_create_nsg_flowlog (subscription, network_interface ,company_region ,nsg_storage_account_id):
    try:
        # configurating network watcher on network interface location
        if (is_network_watcher_in_location(subscription, network_interface["location"])== False):
            network_watcher_configure(subscription, network_interface["location"])
        # creating nsg flow log
        if network_interface["location"] == company_region:
           create_nsg_flowlog(network_interface["location"], network_interface["id"], nsg_storage_account_id, subscription)
    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")

def create_network_integration(subscription: str, subscription_resource_group: str, nsg_storage_account_id: str, company_region: str):
    try:
        network_interface_lst = get_network_interfaces(
            subscription_resource_group["name"],
            subscription
        )
        # configurating network watcher on resource group location
        if (is_network_watcher_in_location(subscription, subscription_resource_group["location"])== False):
            network_watcher_configure(subscription, subscription_resource_group["location"])
        future = []
        with ThreadPoolExecutor(max_workers=10) as executor:
            for network_interface in network_interface_lst:
                try:
                    future.append(executor.submit(configure_and_create_nsg_flowlog,subscription, network_interface,company_region,nsg_storage_account_id))
                except Exception as e:
                    logging.critical(f"{traceback.format_exc()}")
            res = wait(future)
    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")

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
            res = wait(future)    
        #importing diagnostic settings for the resource
        logging.info(f"Importing diagnostic settings")
        print(f"Importing diagnostic settings")
        resource_ids_cli = f"az resource list --location {company_region} --query \"[].id\" --subscription {subscription}"
        resource_ids = azcli(resource_ids_cli)
        resource = ""
        future = []
        with ThreadPoolExecutor(max_workers=10) as executor:
            for resource in resource_ids:
                 future.append(executor.submit(import_diagnostic_settings, resource ,audit_storage_account_id))
            res = wait(future)
    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")

def main():
    try:
        logging.info("STARTING CYNGULAR ONBOARING PROCESS")
        print("STARTING CYNGULAR ONBOARING PROCESS")
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

        # creating thread pool for all the subscriptions
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
    except Exception as e:
        logging.critical(f"{traceback.format_exc()}")

if __name__ == "__main__":
    main()
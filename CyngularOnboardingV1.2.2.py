from concurrent.futures import ThreadPoolExecutor, wait
from typing import List, Dict, Any
import subprocess
import traceback
import time
import sys
import logging
import shlex
import json

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

PRINCIPAL_NAME = "CyngularSPonboardingtest8"
RESOURCE_GROUP = "CyngularRG"
ACTIVITY_FILE = "activity-logs.bicep"
CYNGULAR_PUBLIC_KEY=".local/cyngularPublic.key"


CYNGULAR_APP_ID = "f8597eea-4638-4f2b-be29-66fecf6ff57e"
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
        elif("'audit' is not supported, supported ones are:" in traceback.format_exc()):
            return
        elif("'allLogs' is not supported, supported ones are:" in traceback.format_exc()):
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

# @handle_exception
# def create_cyngular_service_principal():
#     logging.info("Creating cyngular service principal")
#     print("Creating cyngular service principal")
#     args = f"az ad sp create-for-rbac --name {PRINCIPAL_NAME}"

#     res = cli(args)
#     principal_app_id = res["appId"]
#     principal_password = res["password"]
#     principal_tenant = res["tenant"]
#     return principal_app_id, principal_password, principal_tenant

@handle_exception
def create_multi_tenant_service_principal(cyngular_app_id):
    logging.info("Creating cyngular multi tenant service principal")
    print("Creating cyngular multi tenant service principal")
    args = f"az ad sp create --id {cyngular_app_id}"
    res = cli(args)
    principal_object_id = res["id"]
    return principal_object_id



@handle_exception
def set_subscription(subscription_id):
    args = f"az account set --subscription {subscription_id}"
    _ = cli(args)


@handle_exception
def get_principal_object_id(principal_app_id):
    args = f"az ad sp show --id {principal_app_id} --query id"
    principal_object_id = cli(args)
    return principal_object_id

@handle_exception
def assign_subscription_role(subscription_id, principal_object_id, role):
    args = (f"az role assignment create --assignee-object-id {principal_object_id} --assignee-principal-type ServicePrincipal --role \"{role}\" --scope /subscriptions/{subscription_id}")
    cli(args)
def assign_key_vault_role(key_vault_id, principal_object_id, role):
    args = (f"az role assignment create --assignee-object-id {principal_object_id} --assignee-principal-type ServicePrincipal --role \"{role}\" --scope {key_vault_id}")
    cli(args)

@handle_exception
def create_resource_group_with_subscription(subscription, region_for_resource_group, resource_group_name):
    logging.info(f"Creating {resource_group_name} resource group in subscription - {subscription}")
    print(f"Creating {resource_group_name} resource group in subscription - {subscription}")
    args = (f"az group create -l {region_for_resource_group} -n {resource_group_name} --subscription {subscription}")
    cli(args)

@handle_exception
def create_resource_group(resource_group_location, resource_group_name):
    logging.info(f"Creating {resource_group_name} resource group")
    print(f"Creating {resource_group_name} resource group")
    args = (f"az group create -l {resource_group_location} -n {resource_group_name}")
    cli(args)

@handle_exception
def create_audit_storage_account(audit_storage_account_name, company_region):
    logging.info("Creating audit storage account")
    print("Creating audit storage account")
    args = f"az storage account list --resource-group {RESOURCE_GROUP} --query \"[?name=='{audit_storage_account_name}'].id\""
    res = cli(args)
    # create new storage account if there is no audit storage account in  cyngular resource group
    if len(res) == 0:
        args = f"az storage account create -n {audit_storage_account_name} -g {RESOURCE_GROUP} -l {company_region} --sku Standard_LRS --default-action Allow --bypass Logging Metrics AzureServices"
        audit_storage_account_id = cli(args)["id"]
        return audit_storage_account_id
        # Stock Keeping Unit - locally redundant storage
        # network access is allowed

@handle_exception
def create_nsg_storage_account(nsg_storage_account_name, company_region):
    logging.info("Creating nsg storage account")
    print("Creating nsg storage account")
    args = f"az storage account list --resource-group {RESOURCE_GROUP} --query \"[?name=='{nsg_storage_account_name}'].id\""
    # create new storage account if there is no audit storage account in  cyngular resource group
    if len(cli(args)) == 0:
        args = f"az storage account create -n {nsg_storage_account_name} -g {RESOURCE_GROUP} -l {company_region} --sku Standard_LRS"
        nsg_storage_account_id = cli(args)["id"]
        return nsg_storage_account_id

@handle_exception
def get_storage_accounts_connection_string(audit_storage_account_name, nsg_storage_account_name):
    logging.info("Getting the storage accounts connection strings")
    args = f"az storage account show-connection-string -g {RESOURCE_GROUP} -n {audit_storage_account_name} --query connectionString"
    audit_connection_string = cli(args)
    args = f"az storage account show-connection-string -g {RESOURCE_GROUP} -n {nsg_storage_account_name} --query connectionString"
    nsg_connection_string = cli(args)
    return audit_connection_string, nsg_connection_string

@handle_exception
def export_activity_logs(subscription, audit_storage_account_id, company_region):
    logging.info(f"Exporting activity logs from subscription: {subscription}")
    print(f"Exporting activity logs from subscription: {subscription}")
    args = f"az deployment sub create --location {company_region} --name cyngular-activity15-{company_region} --template-file {ACTIVITY_FILE} --parameters settingName=cyngularDiagnostic storageAccountId={audit_storage_account_id} --subscription {subscription}"
    cli(args)

# @handle_exception
# def export_diagnostic_settings(resource, audit_storage_account_id):
#     if any(r in resource for r in ["storageAccounts", "virtualMachines", "networkInterfaces", "disks", "virtualNetworks", "sshPublicKeys", "serverFarms", "sites", "networkwatchers", "snapshots"]):
#         return # since r does not support diagnostic settings
#     if("flexibleServers" in resource or "publicIPAddresses" in resource or "Microsoft.KeyVault/vaults" in resource or "namespaces" in resource or "workspaces" in resource):
#         args = f"az monitor diagnostic-settings create --name CyngularDiagnostic --resource {resource} --storage-account {audit_storage_account_id} --logs {AUDIT_AND_ALL_LOG_SETTINGS}"
#     elif("networkSecurityGroups" in resource or "bastionHosts" in resource or "Microsoft.RecoveryServices/vaults" in resource or "components" in resource): 
#         args = f"az monitor diagnostic-settings create --name CyngularDiagnostic --resource {resource} --storage-account {audit_storage_account_id} --logs {ALL_LOGS_SETTING}"
#     else:
#         args = f"az monitor diagnostic-settings create --name CyngularDiagnostic --resource {resource} --storage-account {audit_storage_account_id} --logs {AUDIT_EVENT_LOG_SETTINGS}"
#     cli(args)

# @handle_exception
# def export_diagnostic_settings(resource, audit_storage_account_id):
#     try:
#         args = f"az monitor diagnostic-settings create --name CyngularDiagnostic --resource {resource} --storage-account {audit_storage_account_id} --logs {AUDIT_AND_ALL_LOG_SETTINGS}"
#         cli(args)
#     except Exception:
#         try:
#             args = f"az monitor diagnostic-settings create --name CyngularDiagnostic --resource {resource} --storage-account {audit_storage_account_id} --logs {ALL_LOGS_SETTING}"
#             cli(args)
#         except Exception:
#             try:
#                 args = f"az monitor diagnostic-settings create --name CyngularDiagnostic --resource {resource} --storage-account {audit_storage_account_id} --logs {AUDIT_EVENT_LOG_SETTINGS}"
#                 cli(args)

@handle_exception
def export_diagnostic_settings(resource, audit_storage_account_id):
    try:
        args = f"az monitor diagnostic-settings create --name CyngularDiagnostic --resource {resource} --storage-account {audit_storage_account_id} --logs {AUDIT_AND_ALL_LOG_SETTINGS}"
        cli(args)
    except Exception:
        try:
            args = f"az monitor diagnostic-settings create --name CyngularDiagnostic --resource {resource} --storage-account {audit_storage_account_id} --logs {ALL_LOGS_SETTING}"
            cli(args)
        except Exception:
            try:
                args = f"az monitor diagnostic-settings create --name CyngularDiagnostic --resource {resource} --storage-account {audit_storage_account_id} --logs {AUDIT_EVENT_LOG_SETTINGS}"
                cli(args)
            except Exception:
                print("not working")


@handle_exception
def get_resource_groups(subscription: str) -> List[Dict[str, Any]]:
    args = f"az group list --subscription {subscription}"
    res = cli(args)
    return [{"name": group["name"], "id": group["id"], "location": group["location"]} for group in res]

# @handle_exception
# def get_network_interfaces(subscription_resource_group: str, subscription: str):
#     logging.info(f"Collecting nsg flow logs from resource group: {subscription_resource_group}")
#     print(f"Collecting nsg flow logs from resource group: {subscription_resource_group}")
        
#     args = f"az network nsg list --resource-group {subscription_resource_group} --subscription {subscription}"
#     res = cli(args)
#     return [{"id": nsg["id"], "location": nsg["location"]} for nsg in res]

# @handle_exception
# def is_network_watcher_in_location(subscription: str, location: str) -> bool:
#     args = f"az network watcher list --query \"[?location=='{location}'].id\" --subscription {subscription}"
#     if cli(args) is None:
#         return True
#     return False

# def network_watcher_configure(subscription: str, location: str, net_watch_rg: str):
#     try:
#         args = f"az network watcher configure -g {net_watch_rg} -l {location} --enabled true --subscription {subscription}"
#         cli(args)
#     except Exception as e:
#         if "NetworkWatcherCountLimitReached" not in str(e):
#             logging.critical(f"{traceback.format_exc()}")

# @handle_exception
# def create_nsg_flowlog(location: str, network_interface_id: str, nsg_storage_account_id: str, subscription: str):
    # args = f"az network watcher flow-log create --location {location} --name cyngular --nsg {network_interface_id} --storage-account {nsg_storage_account_id} --subscription {subscription}"
    # cli(args)

# @handle_exception
# def configure_and_create_nsg_flowlog(subscription, network_interface ,company_region ,nsg_storage_account_id, net_watch_rg: str):
#     # configurating network watcher on network interface location
#     if  not is_network_watcher_in_location(subscription, network_interface["location"]):eliya_sandbox_client@itzikcyngularsecurity.onmicrosoft.com
#         network_watcher_configure(subscription, network_interface["location"], net_watch_rg)
#     # creating nsg flow log
#     if network_interface["location"] == company_region:
#        create_nsg_flowlog(network_interface["location"], network_interface["id"], nsg_storage_account_id, subscription)

# @handle_exception
# def create_network_integration(subscription: str, subscription_resource_group: Dict[str, Any], nsg_storage_account_id: str, company_region: str, net_watch_rg: str):
#     network_interface_lst = get_network_interfaces(subscription_resource_group["name"], subscription)
#     if not is_network_watcher_in_location(subscription, subscription_resource_group["location"]):
#         network_watcher_configure(subscription, subscription_resource_group["location"], net_watch_rg)

#     with ThreadPoolExecutor(max_workers=10) as executor:
#         futures = [
#             executor.submit(configure_and_create_nsg_flowlog, subscription, network_interface, company_region, nsg_storage_account_id, net_watch_rg)
#             for network_interface in network_interface_lst
#         ]
#         wait(futures)
@handle_exception      
def get_principal_tenant_id():
    args = f"az account show --query tenantId"
    principal_tenanat_id = cli(args)
    return principal_tenanat_id

@handle_exception
def configure_network_watcher_if_not_exist(company_region, net_watch_rg, subscription):
    args = f"az network watcher list --subscription {subscription}  --query \"[?location=='{company_region}'].id\""
    net_watch_id = cli(args)
    if len(net_watch_id) == 0:
        args = f"az network watcher configure -l {company_region} --resource-group {net_watch_rg} --enabled true --subscription {subscription}"
        cli(args)
    

@handle_exception      
def get_nsg_in_region(company_region, subscription):
    args = f"az network nsg list --subscription {subscription} --query \"[?location=='{company_region}'].id\""
    nsg_list_in_region=cli(args)
    return nsg_list_in_region

@handle_exception
def get_nsg_with_flow_logs(company_region, subscription):
    args = f"az network watcher flow-log list --subscription {subscription} --location {company_region} --query \"[].targetResourceId\""
    nsg_with_flow_logs=cli(args)
    return nsg_with_flow_logs

@handle_exception
def create_nsg_flowlog(company_region, nsg_id, nsg_storage_account_id, subscription):
    nsg_name = nsg_id.split("/")[-1]
    args = f"az network watcher flow-log create --location {company_region} --name cyngular-{nsg_name} --nsg {nsg_id} --storage-account {nsg_storage_account_id} --subscription {subscription} --no-wait true"
    cli(args)
    print(nsg_id)



@handle_exception
def subscription_manager(region_and_sa_id_dictionary, subscription, principal_object_id, audit_dictionary):
    try:
        logging.info(f"The current subscription is: {subscription}")
        print(f"The current subscription is: {subscription}")

        # assigning cyngular service princicpal the required roles in the
        assign_subscription_role(subscription, principal_object_id, "Reader")
        assign_subscription_role(subscription, principal_object_id, "Disk Pool Operator")
        assign_subscription_role(subscription, principal_object_id, "Data Operator for Managed Disks")
        assign_subscription_role(subscription, principal_object_id, "Disk Snapshot Contributor")
        assign_subscription_role(subscription, principal_object_id, "Microsoft Sentinel Reader")



        region_for_resource_group = next(iter(region_and_sa_id_dictionary))
        net_watch_rg = "CyngularNetWatcherRG"
        create_resource_group_with_subscription(subscription, region_for_resource_group, net_watch_rg)

        # create network watcher resource group

        # getting the subscription resource group
        # resource_groups = get_resource_groups(subscription)
        # future = []
        # with ThreadPoolExecutor(max_workers=10) as executor:
        #     for subscription_resource_group in resource_groups:
        #         future.append(executor.submit(create_network_integration, subscription, subscription_resource_group, nsg_storage_account_id, company_region, net_watch_rg))
        #     _ = wait(future)
        for (company_region, nsg_storage_account_id), (audit_region, audit_storage_account_id) in zip(region_and_sa_id_dictionary.items(), audit_dictionary.items()):
            
            
            # create network watcher resource group
            print('current region:', company_region)
            configure_network_watcher_if_not_exist(company_region, net_watch_rg, subscription)
            # exporting activity logs from the subscription
            export_activity_logs(subscription, audit_storage_account_id, audit_region)
            

            # Get a list of NSGs with flow logs in the specified region
            nsg_with_flow_logs_lst = get_nsg_with_flow_logs(company_region, subscription)
            # Get a list of all NSGs in the specified region
            nsg_list = get_nsg_in_region(company_region, subscription)
            # Find NSGs without NSGs with flow logs
            nsg_result = [nsg for nsg in nsg_list if nsg not in nsg_with_flow_logs_lst]
            print("\n\n--------- START - NSGs with enabled flow logs: ---------\n")
            for nsg_flow_logs in nsg_with_flow_logs_lst:
                print(nsg_flow_logs)
            print("\n---------------------------------------------------------------\n")

            print("\n\n--------- START - conigured flow logs in NSGs: ---------\n")
            future = []
            with ThreadPoolExecutor(max_workers=10) as executor:
                for nsg in nsg_result:
                    future.append(executor.submit(create_nsg_flowlog, company_region, nsg, nsg_storage_account_id, subscription))
            wait(future)

            print("\n\n---------------------------------------------------------------\n")
    
        
        
            #exporting diagnostic settings for the resource
            logging.info("exporting diagnostic settings")
            print("exporting diagnostic settings")
            resource_ids_cli = f"az resource list --location {audit_region} --query \"[].id\" --subscription {subscription}"
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
    location_lst= ["eastasia","southeastasia","australiaeast","australiasoutheast","brazilsouth","canadacentral","canadaeast","switzerlandnorth","germanywestcentral","eastus2","eastus","centralus","italynorth","northcentralus","francecentral","uksouth","ukwest","centralindia","southindia","jioindiawest","japaneast","japanwest","koreacentral","northeurope","norwayeast","swedencentral","uaenorth","westcentralus","westeurope","westus2","westus","southcentralus","westus3","southafricanorth","australiacentral","australiacentral2","westindia","koreasouth","polandcentral","qatarcentral","eastusstg","centraluseuap","eastus2euap","southcentralusstg"]
    # company_region = input(f"{blue}Please enter your company main region here: {white}")
    # while company_region not in location_lst:
    #     company_region = input(f"{red}\n*Invalid region - {blue}to see all the available regions type in cloud shell:\n {green}'az account list-locations --output table'{blue}\nPlease Re-Enter Your Company Main Region Here: {white}")
    region_and_sa_id_dictionary = input("Enter a dictionary using curly braces, e.g., {'eastus': 'storageAccount-eastus.id', 'northeurope': 'storageAccount-northeurope.id'}: \n")
    try:
        # Use eval to evaluate the input string as a Python expression
        region_and_sa_id_dictionary = eval(region_and_sa_id_dictionary)
        # Check if the result is a dictionary
        if not isinstance(region_and_sa_id_dictionary, dict):
            raise ValueError("Input is not a valid dictionary.")
        
    except Exception as e:
        # Handle exceptions, if any
        print("Error:", e)
    

    restart_loop = True

    while restart_loop:
        for key in region_and_sa_id_dictionary.keys():
            if key not in location_lst:
                print(f"'{key}' invalid region")
                restart_loop = True  # Restart the loop
                region_and_sa_id_dictionary = input("Enter nsg storage account region and storage id in dictionary using curly braces, e.g., {'eastus': 'nsgStorageAccountEastusID', 'northeurope': 'nsgStorageAccountNortheuropeID'}:  \n")
                try:
                    # Use eval to evaluate the input string as a Python expression
                    region_and_sa_id_dictionary = eval(region_and_sa_id_dictionary)
                    # Check if the result is a dictionary
                    if not isinstance(region_and_sa_id_dictionary, dict):
                        raise ValueError("Input is not a valid dictionary.")

                except Exception as e:
                    # Handle exceptions, if any
                    print("Error:", e)
                restart_loop = True  # Restart the loop
                break  
        else:
            restart_loop = False

    # CLIENT_NAME = input(f"{blue}Please enter your company name here: {white}")
    # nsg_storage_account_name = "cyngularnsg" + CLIENT_NAME + company_region
    # while(len(CLIENT_NAME) > 24 or len(CLIENT_NAME + company_region) > 24 or len("cyngularaudit" + CLIENT_NAME) > 24 or len(nsg_storage_account_name) > 24):
    #     if(len("cyngularnsg" + CLIENT_NAME + company_region) > 24):
    #         nsg_storage_account_name = "cyngularnsg" + CLIENT_NAME + company_region[0:3]
    #         if(len(nsg_storage_account_name) > 24):
    #             CLIENT_NAME = input(f"{red}\n*Company name is too long{blue}\nPlease re-Enter your company name here: {white}")
    # audit_storage_account_name = "cyngularaudit" + CLIENT_NAME 
    
    # audit_storage_account_id = create_audit_storage_account(audit_storage_account_name, company_region)
    # audit_storage_account_id = input("Enter audit storage account id:")
    audit_dictionary = input("Enter audit storage account region and storage id in dictionary using curly braces, e.g., {'eastus': 'auditStorageAccountEastusID', 'northeurope': 'auditStorageAccountNortheuropeID'}: \n")
    try:
        # Use eval to evaluate the input string as a Python expression
        audit_dictionary = eval(audit_dictionary)
        # Check if the result is a dictionary
        if not isinstance(audit_dictionary, dict):
            raise ValueError("Input is not a valid dictionary.")
        
    except Exception as e:
        # Handle exceptions, if any
        print("Error:", e)

    
    key_vault_id = input("Enter key vault id:")
    # nsg_storage_account_id = create_nsg_storage_account(nsg_storage_account_name, company_region)
    # nsg_storage_account_id = input("Enter nsg storage account id:")

    t0 = time.time()
    # adding extension library named account
    add_account_extension()    # creating cyngular's service principal
    
    principal_object_id = create_multi_tenant_service_principal(CYNGULAR_APP_ID)
    
    # principal_object_id = get_principal_object_id(principal_app_id)
    
    assign_key_vault_role(key_vault_id, principal_object_id, 'Key Vault Secrets User')
    
    # principal_object_id = "a8e14b3c-eca6-4b2b-8d43-360965f4b2ee"
    # creating cyngular's storage accounts resource group
    # create_resource_group(company_region, RESOURCE_GROUP)
    # creating cyngular storage accounts

    # (
    #     audit_connection_string,
    #     nsg_connection_string,
    # ) = get_storage_accounts_connection_string(audit_storage_account_name, nsg_storage_account_name)

    # getting the client subscription ids
    subscriptions_lst = get_subscription_lst()
    # creating thread pool in subscriptions iteration
    with ThreadPoolExecutor(max_workers=10) as executor:
        for subscription in subscriptions_lst:
            executor.submit(subscription_manager, region_and_sa_id_dictionary, subscription, principal_object_id, audit_dictionary)        
    
    principal_tenant_id = get_principal_tenant_id()
    logging.info("FINISHED ONBOARDING")
    print("FINISHED ONBOARDING")
    # data_file_name = f".local/{CLIENT_NAME}_data.txt"
    # with open(data_file_name, "a") as file:
    #     file.write(f"Service Principal App ID: {principal_app_id}\n")
    #     file.write(f"Service Principal Password: {principal_password}\n")
    #     file.write(f"Service Principal Tenant: {principal_tenant}\n")
    #     file.write(f"Audit Storage Account Connection String: {audit_connection_string}\n")
    #     file.write(f"NSG Storage Account Connection String: {nsg_connection_string}\n")
    # import_public_key()
    # encrypt_data(data_file_name)
    #delete_data_file(data_file_name)

    print("ON-BOARDING FINISHED")
    t1 = time.time()
    print(f"onbooarding took:\t {t1-t0} sec")

if __name__ == "__main__":
    main()
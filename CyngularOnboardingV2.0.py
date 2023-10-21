from azure.identity import DefaultAzureCredential
from azure.mgmt.subscription import SubscriptionClient
from azure.mgmt.network import NetworkManagementClient
from azure.mgmt.monitor import MonitorManagementClient
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.graphrbac import GraphRbacManagementClient

from azure.mgmt.monitor.models import DiagnosticSettingsResource, LogSettings, ResultType

from concurrent.futures import ThreadPoolExecutor, wait
from datetime import datetime, timedelta
import logging, time, traceback, requests

RESOURCE_GROUP = "cyngularRG"


logging.basicConfig(
    filename="cyngular_onboarding.log",
    filemode="a",
    format='%(asctime)s %(levelname)s:%(message)s',
    level=logging.INFO,
)

# Error Handling Decorator
def error_handler(func):
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception as e:
            logging.critical(f"An error occurred in {func.__name__}: {e}")
            # logging.critical(traceback.format_exc())
            print(f"An error occurred: {e}")
    return wrapper

@error_handler
def list_subscriptions():
    credential = DefaultAzureCredential()
    subscription_client = SubscriptionClient(credential)
    
    subscriptions = subscription_client.subscriptions.list()
    return [sub.subscription_id for sub in subscriptions]

def list_resource_groups(subscription_id: str):
    credential = DefaultAzureCredential()
    resource_client = ResourceManagementClient(credential, subscription_id)
    
    resource_groups = resource_client.resource_groups.list()
    rg_dict = {rg.name: rg.id for rg in resource_groups}
    return rg_dict

def list_resources(resource_client, region):
    resources = resource_client.resources.list_by_location(region)
    return [res.id for res in resources]

@error_handler
def create_storage_account(storage_client, resource_group):
    # Create Storage Accounts
    sa = storage_client.storage_accounts.create(
        resource_group,
        "auditStorageAccount",
        {
            "location": "eastus",
            "sku": {"name": "Standard_LRS"},
            "kind": "StorageV2"
        }
    ).result()
    return sa

@error_handler
def create_network_watcher(network_client, resource_group):
    # Create Network Watcher
    nw = network_client.network_watchers.create_or_update(
        resource_group,
        "myNetworkWatcher",
        {"location": "eastus"}
    ).result()
    return nw
    

@error_handler # Create Diagnostic settings
def import_diagnostic_settings(monitor_client, resource_id, storage_account_id, log_settings):
    monitor_client.diagnostic_settings.create_or_update(
        resource_uri=resource_id,
        parameters=DiagnosticSettingsResource(
            storage_account_id=storage_account_id,
            logs=[LogSettings(
                category=log_settings,
                enabled=True
            )]
        ),
        name="customDiagnostics"
    )

# Example usage
try:
    resource_id = "/subscriptions/xxxx/resourceGroups/xxxx/providers/Microsoft.Compute/virtualMachines/myVM"
    storage_account_id = audit_storage_account.id  # Replace with the appropriate ID

    if "virtualMachines" in resource_id:
        import_diagnostic_settings(monitor_client, resource_id, storage_account_id, "VMLogSettings")
    elif "networkSecurityGroups" in resource_id:
        import_diagnostic_settings(monitor_client, resource_id, storage_account_id, "NSGLogSettings")
    else:
        logging.warning(f"Unknown resource type for {resource_id}")
except Exception as e:
    logging.critical(f"{e}")

@error_handler
def list_subscriptions(credential):
    subscription_client = SubscriptionClient(credential)
    subscriptions = subscription_client.subscriptions.list()

    subscription_ids = [sub.subscription_id for sub in subscriptions]
    return subscription_ids

audit_nsg, subscription, network_interface, region, storage_account_id2)
@error_handler
def audit_nsg(credential, subscription, network_interface, client_region, resource_group, storage_account_id2):
    print(f"Subscription ID: {subscription}")
    network_client = NetworkManagementClient(credential, subscription)
    monitor_client = MonitorManagementClient(credential, subscription)
    resource_client = ResourceManagementClient(credential, subscription)
    
    # Check Network Watcher presence
    network_watcher_present = False
    for nw in network_client.network_watchers.list_all():
        if nw.location == client_region:
            network_watcher_present = True
            break

    if not network_watcher_present:
        network_client.network_watchers.create_or_update(
            "NetworkWatcherRG", "NetworkWatcher" + client_region,
            {"location": client_region}
        )

    # List all NSGs in the resource group
    nsg_list = []
    for nsg in network_client.network_security_groups.list(resource_group):
        nsg_list.append({"id": nsg.id, "location": nsg.location})

    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = []
        for nsg in nsg_list:
            # Only create flow logs if NSG location matches company_region
            if nsg['location'] == client_region:
                futures.append(executor.submit(create_nsg_flowlog, network_client, nsg['id'], nsg_storage_account_id))

        wait(futures)

    # List all resource groups in the subscription
    for resource_group in resource_client.resource_groups.list():
        resource_group_name = resource_group.name
        # List all NSGs in the resource group
        for nsg in network_client.network_security_groups.list(resource_group_name):
            nsg_id = nsg.id
            print(f"NSG ID: {nsg_id}")
            # Get NSG audit logs
            start_time = datetime.now() - timedelta(days=7)
            end_time = datetime.now()
            logs = monitor_client.activity_logs.list(
                filter=f"eventTimestamp ge {start_time} and eventTimestamp le {end_time} and resourceUri eq {nsg_id}",
                select="operationName,status,caller,category",
                result_type=ResultType.Data,
            )
            for log in logs:
                print(log.as_dict())


def subscription_manager(client_region, subscription, principal_object_id, storage_account_id1, storage_account_id2):
    logging.info(f"The current Subscription Id is: {subscription}")
    credential = DefaultAzureCredential()
    resource_client = ResourceManagementClient(credential, subscription)

    # assigning cyngular service principal the required roles in the subscription
    roles = [
        "Reader",
        "role Disk Pool Operator",
        "role Data Operator for Managed Disks",
        "role Disk Snapshot Contributor",
        "role Microsoft Sentinel Reader"
    ]
    for role in roles:
        assign_subscription_role(subscription, principal_object_id, role)

    # exporting activity logs from the subscription
    audit_logs(subscription, storage_account_id1, client_region)
    
    # create network watcher resource group
    create_resource_group_with_subscription(subscription, client_region, "NetworkWatcherRG")


    # Assuming you've defined a function named `get_network_interfaces` to get a list of network interfaces
    network_interface_lst = get_network_interfaces(subscription)

    with ThreadPoolExecutor(max_workers=10) as executor:
        resource_groups = list_resource_groups(subscription)
        futures = [
            executor.submit(audit_nsg, credential, subscription, network_interface, client_region, rg, storage_account_id2)
            for network_interface in network_interface_lst
            for rg in resource_groups
        ]
        wait(futures)

    logging.info("Importing diagnostic settings for the resource")
    resource_ids = list_resources(resource_client, client_region)

    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = [
            executor.submit(import_diagnostic_settings, resource, storage_account_id1)
            for resource in resource_ids
        ]
        wait(futures)

@error_handler
def main():
    logging.info("STARTING CYNGULAR ONBOARING PROCESS")
    print("STARTING CYNGULAR ONBOARING PROCESS")
    print("=====================================\n")
    location_lst= ["eastasia","southeastasia","australiaeast","australiasoutheast","brazilsouth","canadacentral","canadaeast","switzerlandnorth","germanywestcentral","eastus2","eastus","centralus","northcentralus","francecentral","uksouth","ukwest","centralindia","southindia","jioindiawest","japaneast","japanwest","koreacentral","northeurope","norwayeast","swedencentral","uaenorth","westcentralus","westeurope","westus2","westus","southcentralus","westus3","southafricanorth","australiacentral","australiacentral2","westindia","koreasouth","polandcentral","qatarcentral","eastusstg","centraluseuap","eastus2euap","southcentralusstg"]
    company_region = input("Please enter your company main region here: ")
    while company_region not in location_lst:
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
    
    credential = DefaultAzureCredential()
    
    subs = list_subscriptions(credential)
    
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
        for sub in subs:
            executor.submit(subscription_manager, company_region, sub, principal_object_id, audit_storage_account_id, nsg_storage_account_id)        

    # with ThreadPoolExecutor(max_workers=10) as executor:
    #     futures = [
    #         executor.submit(configure_and_create_nsg_flowlog, subscription, network_interface, company_region, nsg_storage_account_id)
    #         for network_interface in network_interface_lst
    #     ]
    #     wait(futures)
    
        
    logging.info("Cyngular Onboarding Process Completed")
    print("Cyngular Onboarding Process Completed")
    # data_file_name = f"{company_name}_data.txt"
    # with open(data_file_name, "a") as file:
    #     file.write(f"Service Principal App ID: {principal_app_id}\n")
    #     file.write(f"Service Principal Password: {principal_password}\n")
    #     file.write(f"Service Principal Tenant: {principal_tenant}\n")
    #     file.write(f"Service Principal Audit Storage Account Connection String: {audit_connection_string}\n")
    #     file.write(f"Service Principal NSG Storage Account Connection String: {nsg_connection_string}\n")
    # import_public_key()
    # encrypt_data(data_file_name)
    # #delete_data_file(data_file_name)
    t1 = time.time()
    print(f"onbooarding took:\t {t1-t0} sec")
if __name__ == "__main__":
    main()

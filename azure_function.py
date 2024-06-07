import logging
import traceback
import subprocess
import json
import shlex
import time

logging.basicConfig(
    filename="onboarding_audit.log",
    filemode="a",
    format="%(asctime)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)

ALL_AND_AUDIT_LOG_SETTINGS = '[{\"categoryGroup\":\"audit\",\"enabled\":true,\"retention-policy\":{\"enabled\":false,\"days\":30}},{\"categoryGroup\":\"allLogs\",\"enabled\":true,\"retention-policy\":{\"enabled\":false,\"days\":30}}]'
ALL_LOGS_SETTING = '[{\"categoryGroup\":\"allLogs\",\"enabled\":true,\"retention-policy\":{\"enabled\":false,\"days\":30}}]'
AUDIT_EVENT_LOG_SETTINGS = '[{\"category\":\"AuditEvent\",\"enabled\":true,\"retention-policy\":{\"enabled\":false,\"days\":30}}]'
ALL_AND_AUDIT_LOG_SETTINGS = '[{"categoryGroup":"audit","enabled":true,"retention-policy":{"enabled":false,"days":30}},{"categoryGroup":"allLogs","enabled":true,"retention-policy":{"enabled":false,"days":30}}]'
ALL_LOGS_SETTING = '[{"categoryGroup":"allLogs","enabled":true,"retention-policy":{"enabled":false,"days":30}}]'
AUDIT_EVENT_LOG_SETTINGS = '[{"category":"AuditEvent","enabled":true,"retention-policy":{"enabled":false,"days":30}}]'
ACTIVITY_LOG_SETTINGS = '[{"category":"Security","enabled":true},{"category":"Administrative","enabled":true},{"category":"ServiceHealth","enabled":true},{"category":"Alert","enabled":true},{"category":"Recommendation","enabled":true},{"category":"Policy","enabled":true},{"category":"Autoscale",enabled:true},{"category":"ResourceHealth","enabled":true}]'

def handle_exception(func):
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception:
            logging.critical(f"{traceback.format_exc()}")
    return wrapper

def azure_cli(command):
    # Splitting the command into parts for subprocess
    command_parts = shlex.split(command)

    try:
        # Execute the command
        result = subprocess.run(command_parts, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        # Extracting the output
        output = result.stdout
        try:
            # Trying to parse the output as JSON
            json_output = None
            json_output = json.loads(output)
            return json_output
        except json.JSONDecodeError:
            # Output is not JSON
            return output

    except subprocess.CalledProcessError as e:
        # There was an error executing the command
        if 'does not support diagnostic settings' not in e.stderr and 'is not supported' not in e.stderr:
            print(f"Command (error): {command}")
            print(f"Error: {e}")
            logging.info(f"Error: {e}")
            logging.info(f"Error Output: {e.stderr}")
            return 'error'

@handle_exception
def update_sp_id(sp_id):
    logging.info(f"Update a Service Principal ID in config file")
    print(f"Update a Service Principal ID in config file")

    # Load configuration from file
    with open('cyngular_config.json', 'r') as file:
        cyngular_config = json.load(file)
    
    cyngular_config['servicePrincipalID'] = sp_id

    # Write the updated data back to the JSON file
    with open('cyngular_config.json', 'w') as file:
        json.dump(cyngular_config, file, indent=4)

@handle_exception
def validate_client_config_file(config):
    storage_accounts = config['storageAccounts']  # Storage account information

    allowed_locations = ["eastasia","southeastasia","australiaeast","australiasoutheast","brazilsouth","canadacentral","canadaeast","switzerlandnorth","germanywestcentral","eastus2","eastus","centralus","northcentralus","francecentral","uksouth","ukwest","centralindia","southindia","jioindiawest","japaneast","japanwest","koreacentral","northeurope","norwayeast","swedencentral","uaenorth","westcentralus","westeurope","westus2","westus","southcentralus","westus3","southafricanorth","australiacentral","australiacentral2","westindia","koreasouth","polandcentral","qatarcentral","eastusstg","centraluseuap","eastus2euap","southcentralusstg"]
    for item in storage_accounts:
        storageAccountId = item['id']
        location = item['location']

        #pattern = r'/subscriptions/[a-f0-9-]+/resourceGroups/[^/]+/providers/Microsoft\.Storage/storageAccounts/[^/]+'
        #if not re.fullmatch(pattern, storageAccountId):
        #    print(f"Incorrect storage account name: {storageAccountId}")
        #    exit()
        
        if location not in allowed_locations:
            print(f"Incorrect location: {location}")
            exit()

@handle_exception
def validate_cyngular_config_file(config):
    data_sources = config['dataSources']  # Data sources
    sp_permissions = config['spPermissions']  # Service principal permissions
    cyngular_app_id = config['cyngularAppId']  # Service principal permissions
    activity_file = config['activityFile']  # Activity file location

    allowed_data_sources = {"Service Principal", "Subscriptions Permission", "NSG Flow Logs", "Activity Logs", "Audit Events"}
    # Convert list to a set and check difference
    disallowed_items = set(data_sources) - allowed_data_sources
    if disallowed_items:
        print(f"Disallowed data sources found: {disallowed_items}")
        exit()
    
    allowed_permissions = {"Reader", "Disk Pool Operator", "Data Operator for Managed Disks", "Disk Snapshot Contributor", "Microsoft Sentinel Reader", "API Management Workspace Reader"}
    # Convert list to a set and check difference
    disallowed_permissions = set(sp_permissions) - allowed_permissions
    if disallowed_permissions:
        print(f"Disallowed data sources found: {disallowed_permissions}")
        exit()

    if len(cyngular_app_id) != 36:
        print(f"Cyngular app_id is incorrect")
        exit()

    #if not os.path.exists(activity_file):
    #    print(f"Activity file is incorrect")
    #    exit()

@handle_exception
def azure_login():
    logging.info("Authenticate with Azure")
    print("Authenticate with Azure")
    args = "az login --identity"
    azure_cli(args)    

@handle_exception
def add_account_extension():
    logging.info("Adding extension named account")
    print("Adding 'az account' extension")
    args = "az extension add --name account"
    _ = azure_cli(args)    

@handle_exception
def get_subscriptions_list():
    logging.info("Listing client subscription ids")
    print("Listing client subscription ids")
    
    args = "az account subscription list --query [].subscriptionId"
    sub_list = azure_cli(args)
    
    return sub_list

@handle_exception
def create_sp(cyngular_app_id):
    logging.info(f"Create a Service Principal")
    print(f"Create a Service Principal")

    args = f"az ad sp create --id {cyngular_app_id}"
    response = azure_cli(args)

    if response != 'error' and 'id' in response:
        update_sp_id(response['id'])
        return response['id']
    else:
        exit()

@handle_exception
def delete_subscription_activity_logs(subscription_id, target_storage_account, activity_file):

    args = f"""az monitor diagnostic-settings subscription delete 
            --name cyngularDiagnostic 
            --subscription {subscription_id} -y """
    azure_cli(args)

@handle_exception
def set_subscription_activity_logs(subscription_id, target_storage_account, activity_file):
    logging.info(f"Exporting activity logs from subscription: {subscription_id}")
    print(f"Exporting activity logs from subscription: {subscription_id}")

    #args = f"""az deployment sub create 
    #        --location {target_storage_account['location']} 
    #        --template-file {activity_file} --parameters 
    #        settingName=cyngularDiagnostic 
    #        storageAccountId={target_storage_account['id']} 
    #        --subscription {subscription_id}"""
    
    args = f"""az monitor diagnostic-settings subscription create 
            -n cyngularDiagnostic 
            --location {target_storage_account['location']} 
            --storage-account {target_storage_account['id']} 
            --logs \"{ACTIVITY_LOG_SETTINGS}\"
            --subscription {subscription_id}"""
    
    azure_cli(args)

@handle_exception
def set_sp_permissions(subscription_id, sp_object_id, sp_permissions):
    logging.info(f"Granting SP permissions for subscription: {subscription_id}")
    print(f"Granting SP permissions for subscription: {subscription_id}")

    for sp_permission in sp_permissions:
        args = f"""az role assignment create 
        --assignee-object-id {sp_object_id} --assignee-principal-type ServicePrincipal 
        --role \"{sp_permission}\" 
        --scope /subscriptions/{subscription_id}"""
        azure_cli(args)

@handle_exception
def get_resources_by_loaction(subscription_id, storage_account):
    logging.info(f"List All Resources in the Specific Location - Subscription: {subscription_id} - Location: {storage_account['location']}")
    print(f"List All Resources in the Specific Location - Subscription: {subscription_id} - Location: {storage_account['location']}")

    args = f"""az resource list 
            --location {storage_account['location']} 
            --query \"[].id\" 
            --subscription {subscription_id}"""
    resource_ids = azure_cli(args)
    
    return resource_ids

@handle_exception
def delete_resource_activity_logs(subscription_id, storage_account, resource_id):
    if any(r in resource_id for r in ["storageAccounts", "virtualMachines", "networkInterfaces", "disks", "virtualNetworks", "sshPublicKeys", "serverFarms", "sites", "networkwatchers", "snapshots"]):
        return
    
    args = f"az monitor diagnostic-settings delete --name CyngularDiagnostic --resource {resource_id} --subscription {subscription_id}"
    res = azure_cli(args)

@handle_exception
def set_resource_activity_logs(subscription_id, storage_account, resource_id):
    logging.info("Configure Resources Activity Logs")
    print("Configure Resources Activity Logs")
        
    if any(r in resource_id for r in ["storageAccounts", "virtualMachines", "networkInterfaces", "disks", "virtualNetworks", "sshPublicKeys", "serverFarms", "sites", "networkwatchers", "snapshots"]):
        return
    
    if ("Microsoft.Sql" in resource_id or "flexibleServers" in resource_id or "publicIPAddresses" in resource_id or "vaults" in resource_id or "namespaces" in resource_id or "workspaces" in resource_id):
        args = f"""az monitor diagnostic-settings create 
        --name CyngularDiagnostic 
        --resource {resource_id} 
        --storage-account {storage_account['id']} 
        --logs '{ALL_AND_AUDIT_LOG_SETTINGS}' 
        --subscription {subscription_id}"""
    
    elif ("networkSecurityGroups" in resource_id or "bastionHosts" in resource_id or "components" in resource_id):
        args = f"""az monitor diagnostic-settings create 
        --name CyngularDiagnostic 
        --resource {resource_id} 
        --storage-account {storage_account['id']} 
        --logs '{ALL_LOGS_SETTING}' 
        --subscription {subscription_id}"""
    
    else:
        args = f"""az monitor diagnostic-settings create 
        --name CyngularDiagnostic 
        --resource {resource_id} 
        --storage-account {storage_account['id']} 
        --logs '{AUDIT_EVENT_LOG_SETTINGS}' 
        --subscription {subscription_id}"""
    
    azure_cli(args)

@handle_exception
def set_network_watcher(subscription_id, storage_account):
    logging.info(f"Configure Network Watcher - Subscription: {subscription_id} - Location: {storage_account['location']}")
    print(f"Configure Network Watcher - Subscription: {subscription_id} - Location: {storage_account['location']}")

    rg_name = "NetworkWatcherRG"
    args = f"""az network watcher list 
            --query \"[?location=='{storage_account['location']}'].id\" 
            --subscription {subscription_id}"""
    
    is_network_watcher = azure_cli(args)
    if not is_network_watcher:
        args = f"""az network watcher configure 
                -g {rg_name} 
                -l {storage_account['location']} 
                --enabled true 
                --subscription {subscription_id}"""
        azure_cli(args)
        time.sleep(30)
    else:
        logging.info(f"Network watcher already exists for subscription: {subscription_id} and location: {storage_account['location']}")
        print(f"Network watcher already exists for subscription: {subscription_id} and location: {storage_account['location']}")

@handle_exception
def get_nsg_list(subscription_id, storage_account):
    logging.info(f"List All NSG in the Specific Location Without Flowlogs - Subscription: {subscription_id} - Location: {storage_account['location']}")
    print(f"List All NSG in the Specific Location Without Flowlogs - Subscription: {subscription_id} - Location: {storage_account['location']}")

    args = f"""az network watcher flow-log list
            --query '[].targetResourceId'
            --location {storage_account['location']} 
            --subscription {subscription_id}"""
    nsg_with_flow_logs = azure_cli(args)

    args = f"""az network nsg list
            --query \"[?location=='{storage_account['location']}'].id\" 
            --subscription {subscription_id}"""
    nsg_list = azure_cli(args)

    #Remove all nsg ids that already has nsg flow logs
    nsg_without_flow_logs = list(set(nsg_list)-set(nsg_with_flow_logs))
    
    return nsg_without_flow_logs

@handle_exception
def set_nsg_flow_logs(subscription_id, storage_account, nsg_id):
    nsg_name = nsg_id.split('/')[-1]

    logging.info(f"Configure NSG Flow Logs - Subscription: {subscription_id} - Location: {storage_account['location']} - NSG Name: {nsg_name}")
    print(f"Configure NSG Flow Logs - Subscription: {subscription_id} - Location: {storage_account['location']} - NSG Name: {nsg_name}")

    args = f"""az network watcher flow-log create 
    --location {storage_account['location']} 
    --name {nsg_name} 
    --nsg {nsg_id} 
    --no-wait 1 
    --storage-account {storage_account['id']} 
    --subscription {subscription_id}"""
    azure_cli(args)
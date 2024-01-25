from azure.identity import DefaultAzureCredential, ManagedIdentityCredential, AzureCliCredential, ChainedTokenCredential

from azure.mgmt.authorization import AuthorizationManagementClient
from azure.mgmt.subscription import SubscriptionClient
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.storage import StorageManagementClient
from azure.mgmt.network import NetworkManagementClient
from azure.mgmt.monitor import MonitorManagementClient
from azure.mgmt.monitor.models import DiagnosticSettingsResource, LogSettings, ResultType
# from azure.eventhub import EventHubProducerClient

from concurrent.futures import ThreadPoolExecutor, wait
from datetime import datetime, timedelta
import logging, time, requests, re, os, traceback
from dotenv import load_dotenv

blue = "\033[1;34m"
red = "\033[1;91m"
magenta = "\033[1;35m"
green = "\033[1;92m"
white = "\x1b[0m"

logging.basicConfig(
    filename="cyngular_onboarding.log",
    filemode="a",
    format='%(asctime)s %(levelname)s:%(message)s',
    level=logging.INFO,
)

# MGMGT_SUBSCRIPTION_ID = os.getenv("MGMGT_SUBSCRIPTION_ID")
# AZURE_TENANT_ID = os.getenv("AZURE_TENANT_ID")

AUTH_METHOD = "dev" # or "deploy" for deployment
RESOURCE_GROUP = "cyngularRG"
MGMGT_SUBSCRIPTION_ID = '373cb248-9e3b-4f65-8174-c72d253103ea'
AZURE_TENANT_ID = '4d6cfaa5-15d3-499d-ab46-08ddf9b43031'
CLIENT_SECRET = 'abcdsty'
ACTIVITY_FILE_NAME = "activity-logs.bicep"

# Error Handling Decorator
def error_handler(func):
    def wrapper(*args, **kwargs):
        try:
            logging.info(f"Calling {func.__name__} with args: {args} and kwargs: {kwargs}")
            return func(*args, **kwargs)
        except Exception as e:
            logging.critical(f"An error occurred in {func.__name__}: {e}")
            logging.critical(traceback.format_exc())
            print(f"{red}Error in {func.__name__}: {e}{white}")
    return wrapper

# accepts an optional parameter auth_method which defaults to the string "dev".
class AzureSession():
    def __init__(self, subscription_id, auth_method="dev"):
        if auth_method == "dev":
            self.credential = DefaultAzureCredential()
        elif auth_method == "deploy":
            self.credential = ManagedIdentityCredential()
        
        self.azure_cli = AzureCliCredential()
        self.credential_chain = ChainedTokenCredential(self.credential, self.azure_cli)

        self.auth_client = AuthorizationManagementClient(self.credential, subscription_id)
        self.subscription_client = SubscriptionClient(self.credential)
        self.resource_client = ResourceManagementClient(self.credential, subscription_id)
        self.network_client = NetworkManagementClient(self.credential, subscription_id)
        self.monitor_client = MonitorManagementClient(self.credential, subscription_id)
        self.storage_client = StorageManagementClient(self.credential, subscription_id)        
        # self.EventHub_Client = EventHubProducerClient(self.credential, eventhub_name, credential_chain)        

        # Get token for Microsoft Graph API
        self.token = self.credential.get_token("https://graph.microsoft.com/.default")
        self.headers = {
            "Authorization": f"Bearer {self.token.token}",
            "Content-Type": "application/json"
        }
        
    def get_graph_endpoint(self, endpoint: str) -> str:
        tenant_id = AZURE_TENANT_ID # self.get_tenant_id()
        base_url = f"https://graph.microsoft.com/v1.0/{tenant_id}"
        return f"{base_url}/{endpoint}"

    @property
    def endpoint_app_registration(self):
        return self.get_graph_endpoint("applications")

    @property
    def endpoint_service_principals(self):
        return self.get_graph_endpoint("servicePrincipals")

    @property
    def endpoint_role_assignment(self):
        return self.get_graph_endpoint("roleAssignments")

    @error_handler
    def _generate_azure_compliant_name(self, prefix, client_name):
        """Generate a valid Azure name."""
        # Concatenate prefix and client_name, ensure it's alphanumeric, and truncate to 64 chars
        name = f"{prefix}-{client_name}"
        name = re.sub(r'[^a-zA-Z0-9]', '', name)[:64]
        return name

    @error_handler
    def create_application(self, client_name, prefix):
        app_name = self._generate_azure_compliant_name(client_name, prefix)

        # Create the Azure AD application
        payload = {
            "displayName": app_name,
            # "identifierUris": [f"https://{app_name}.com"]
        }
        response = requests.post(self.endpoint_app_registration, headers=self.headers, json=payload)
        if response.status_code != 201:
            logging.error(f"Failed to create application. Response: {response.text}")
            return None

        app_info = response.json()
        if app_info:
            logging.info(f"App Info: {app_info}")
            # app_id = app_info["app_id"]
        else:
            logging.error("Failed to create application.")

        # Assign a client secret to the application
        secret_payload = {
            "passwordCredential": {
                "displayName": f"{app_name}-{CLIENT_SECRET}"
            }
        }
        secret_endpoint = f"{self.endpoint_app_registration}/{app_info['appId']}/addPassword"
        secret_response = requests.post(secret_endpoint, headers=self.headers, json=secret_payload)
        if secret_response.status_code != 201:
            logging.error(f"Failed to create secret. Response: {secret_response.text}")
            return None

        secret_data = secret_response.json()

        result = {
            "app_id": app_info.get("app_id"), #app_info["appId"],
            "tenant_id": AZURE_TENANT_ID,
            "client_secret": secret_data["secretText"]
        }
        return result

    @error_handler
    def get_principal_object_id(self, app_id):
        """Get the principal object ID given the application ID."""
        response = requests.get(f"{self.endpoint_service_principals}/{app_id}", headers=self.headers)
        sp_data = response.json()
        return sp_data["id"]
    
    @error_handler
    def assign_subscription_role(self, subscription_id, principal_object_id, role_name):        
        
        # Find the role definition by its name (this assumes that the role exists at the subscription level)
        role_defs = list(self.auth_client.role_definitions.list(
            filter=f"name eq 'Microsoft.Authorization/roleDefinitions/{role_name}'"
        ))
        
        if not role_defs:
            raise ValueError(f"Role '{role_name}' not found.")
        
        role_def = role_defs[0]
        
        role_assignment_params = {
            "role_definition_id": role_def.id,
            "principal_id": principal_object_id,
            "principal_type": "ServicePrincipal",
            # "resourceScope": f"/subscriptions/{subscription_id}"

        }
        
        self.auth_client.role_assignments.create(
            scope=f"/subscriptions/{subscription_id}",
            parameters=role_assignment_params
        )
        # response = requests.post(self.endpoint_role_assignment, headers=self.headers, json=role_assignment_params)

        # # Check if the assignment was successful
        # if response.status_code != 201:
        #     raise ValueError(f"Failed to assign role. Error: {response.json()}")


    @error_handler
    def get_tenant_id(self):
        # List all subscriptions
        subscriptions = list(self.subscription_client.subscriptions.list())
        if subscriptions:
            # Assuming that all subscriptions have the same tenant_id
            tenant_id = subscriptions[0].tenant_id
            logging.info(f"Retrieved Tenant ID: {tenant_id}")
            print(f"{green}Tenant ID: {tenant_id}{white}")
            return tenant_id
        else:
            logging.error("No subscriptions found.")
            return None
    
    @error_handler
    def create_resource_group(self, client_name, prefix, location):
        """Create a new resource group."""
        resource_group_name = self._generate_azure_compliant_name(prefix, client_name) + "rg"
        params = {
            "location": location
        }
        self.resource_client.resource_groups.create_or_update(resource_group_name, params)
        return resource_group_name
    
    @error_handler
    def create_storage_account(self, location, client_name, prefix, rg):
        # Azure storage account names need to be between 3 and 24 characters in length and use numbers and lower-case letters only.
        storage_account_name = self._generate_azure_compliant_name(prefix, client_name).lower()[:20] + "stor"

        create_params = {
            "sku": {
                "name": "Standard_LRS"
            },
            "kind": "StorageV2",
            "location": location
        }

        # Create the storage account
        storage_account = self.storage_client.storage_accounts.begin_create(
            rg,
            storage_account_name,
            create_params
        ).result()
        print(storage_account)
        return storage_account_name, storage_account.id

    @error_handler
    def deploy_activity_logs(self, location, activity_file_path, setting_name, storage_account_id, subscription_id):        
        deployment_properties = {
            "mode": "Incremental",
            "template_link": {
                "uri": activity_file_path,
                "content_version": "1.0.0.0"
            },
            "parameters": {
                "settingName": {"value": setting_name},
                "storageAccountId": {"value": storage_account_id}
            }
        }
        
        deployment_async_operation = self.resource_client.deployments.begin_create_or_update_at_subscription_scope(
            deployment_name="ActivityLogDeployment",
            properties=deployment_properties,
            location=location
        )
        
        deployment_async_operation.result()
        return deployment_async_operation.status()

@error_handler
def list_subscriptions(credential):
    subscription_client = SubscriptionClient(credential)
    subscriptions = subscription_client.subscriptions.list()

    subscription_ids = [sub.subscription_id for sub in subscriptions]
    return subscription_ids

@error_handler
def list_resource_groups(resource_client):
    resource_groups = resource_client.resource_groups.list()
    rg_dict = {rg.name: rg.id for rg in resource_groups}
    return rg_dict

@error_handler
def list_resource_ids(resource_client, region):
    resources = resource_client.resources.list_by_location(region)
    return [res.id for res in resources]

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
        name="cyngularDiagnostics"
    )

@error_handler
def apply_diagnostic_settings(resource_id, monitor_client, storage_account_id):
    if "virtualMachines" in resource_id:
        import_diagnostic_settings(monitor_client, resource_id, storage_account_id, "VMLogSettings")
    elif "networkSecurityGroups" in resource_id:
        import_diagnostic_settings(monitor_client, resource_id, storage_account_id, "NSGLogSettings")
    else:
        logging.warning(f"Unknown resource type for {resource_id}")

@error_handler
def create_nsg_flowlog(network_client, location, network_interface_id, nsg_storage_account_id):
    flow_log_parameters = {
        'location': location,
        'target_resource_id': network_interface_id,
        'storage_id': nsg_storage_account_id,
        'enabled': True
    }
    network_client.flow_logs.create_or_update(
        "NetworkWatcherRG", 
        "cyngularFlowLog",
        flow_log_parameters
    )
    
@error_handler
def nsg_audit_logs(session, subscription, client_region, resource_group, nsg_storage_account_id):
    resource_group_name = resource_group.name
    print(f"resource group name: {resource_group_name}")
    print(f"rg location: {client_region}")
    
    # Check Network Watcher presence
    network_watcher_present = False
    for nw in session.network_client.network_watchers.list_all():
        if nw.location == client_region:
            network_watcher_present = True
            break

    if not network_watcher_present:
        session.network_client.network_watchers.create_or_update(
            "NetworkWatcherRG", "NetworkWatcher" + client_region,
            {"location": client_region}
        )
            
    network_interface_lst = list(session.network_client.network_interfaces.list(resource_group_name))
    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = [
            executor.submit(create_nsg_flowlog, session.network_client, network_interface["location"], network_interface["id"], nsg_storage_account_id) for network_interface in network_interface_lst
        ]
        wait(futures)
    # List all NSGs in the resource group
    for nsg in session.network_client.network_security_groups.list(resource_group_name):
        nsg_id = nsg.id
        print(f"NSG ID: {nsg_id}")
        # Get NSG audit logs
        start_time = datetime.now() - timedelta(days=7)
        end_time = datetime.now()
        logs = session.monitor_client.activity_logs.list(
            filter=f"eventTimestamp ge {start_time} and eventTimestamp le {end_time} and resourceUri eq {nsg_id}",
            select="operationName,status,caller,category",
            result_type=ResultType.Data,
        )
        for log in logs:
            print(log.as_dict())

def subscription_manager(subscription, session, client_region, audit_storage_account_id, nsg_storage_account_id, app_id):
    logging.info(f"The current Subscription Id is: {subscription}")
    principal_object_id = session.get_principal_object_id(app_id)

    # assigning cyngular service principal the required roles in the subscription
    roles = [
        "Reader",
        "role Disk Pool Operator",
        "role Data Operator for Managed Disks",
        "role Disk Snapshot Contributor",
        "role Microsoft Sentinel Reader"
    ]
    for role in roles:
        session.assign_subscription_role(subscription, principal_object_id, role)
    
    # exporting activity logs from the subscription
    deployment_status = session.deploy_activity_logs(
        location=client_region,
        activity_file_path=ACTIVITY_FILE_NAME,
        setting_name="cyngularDiagnostic",
        storage_account_id=audit_storage_account_id,
        subscription_id=subscription
    )
    if deployment_status == "Succeeded":
        logging.info("Deployment of activity logs succeeded!")
    else:
        logging.warning(f"Deployment of activity logs returned status: {deployment_status}")

    # create network watcher resource group
    nw_rg = session.create_resource_group(CLIENT_NAME, "NetworkWatcher", client_region)

    # exporting activity logs from the subscription
    nsg_audit_logs(subscription, audit_storage_account_id, client_region)
    
    with ThreadPoolExecutor(max_workers=10) as executor:
        resource_groups = list_resource_groups(subscription)
        futures = [
            executor.submit(nsg_audit_logs, session, subscription, client_region, rg, nsg_storage_account_id)
            for rg in resource_groups
        ]
        wait(futures)

    logging.info("Importing diagnostic settings for the resource")
    resource_ids = list_resource_ids(session.resource_client, client_region)

    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = [executor.submit(apply_diagnostic_settings, resource_id, session.monitor_client, audit_storage_account_id) for resource_id in resource_ids]
        wait(futures)
        
@error_handler
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
                CLIENT_NAME = input(f"{red}\n*Your company name is too long{blue}\nPlease re-Enter your company name here: {white}")
    audit_storage_account_name = "cyngularaudit" + CLIENT_NAME 
    
    t0 = time.time()
    # load_dotenv()
    
    session = AzureSession(MGMGT_SUBSCRIPTION_ID, AUTH_METHOD)  
    
    # Register application - Service Principle in Azure AD.
    app_details = session.create_application(client_name=CLIENT_NAME, prefix="App")
    print(f"{blue}app details - {app_details}-{white}")
      
    # creating cyngular's storage accounts resource group
    cyngular_rg = session.create_resource_group(CLIENT_NAME, "RG", company_region)

    audit_storage_account_name, audit_storage_account_id = session.create_storage_account(company_region, CLIENT_NAME, audit_storage_account_name, cyngular_rg)
    nsg_storage_account_name, nsg_storage_account_id = session.create_storage_account(company_region, CLIENT_NAME, nsg_storage_account_name, cyngular_rg)

    subscriptions = list(session.subscription_client.subscriptions.list())
    print(f"{green}subs info - {subscriptions}-{white}")
    future = []
    with ThreadPoolExecutor(max_workers=10) as executor:
        for sub in subscriptions:
            print(f"{green}sub info - {sub}-{white}")
            sub_id = sub.subscription_id
            session = AzureSession(sub_id, AUTH_METHOD)  
            print(f"on sub_id - {sub_id}")
            future.append(executor.submit(subscription_manager, sub_id, session, company_region, audit_storage_account_id, nsg_storage_account_id, app_details["app_id"]))       
        res = wait(future)    
        print(f"{magenta}after executor - {res}-{white}")
        
    logging.info("Cyngular Onboarding Process Completed")
    print("Cyngular Onboarding Process Completed")
    # data_file_name = f"{company_name}_data.txt"
    # with open(data_file_name, "a") as file:
    #     file.write(f"Service Principal App ID: {app_id}\n")
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


# from azure.identity import DefaultAzureCredential
# from azure.mgmt.graphrbac import GraphRbacManagementClient

# def create_cyngular_service_principal(PRINCIPAL_NAME: str):
#     # Get credentials
#     credential = DefaultAzureCredential()

#     # Initialize the GraphRbacManagementClient
#     rbac_client = GraphRbacManagementClient(credential, "<YOUR_TENANT_ID>")

#     # Create service principal
#     sp_params = {
#         "app_id": PRINCIPAL_NAME,  # This should be a unique identifier
#         "account_enabled": True
#     }
#     sp_result = rbac_client.service_principals.create(sp_params)

#     # Extracting information
#     principal_app_id = sp_result.app_id
#     # The SDK doesn't return the password directly as the CLI does. 
#     # You'd typically set this up separately or use a certificate.
#     principal_password = None
#     principal_tenant = "<YOUR_TENANT_ID>"

#     return principal_app_id, principal_password, principal_tenant


# def get_principal_object_id(principal_app_id: str) -> str:
#     from azure.mgmt.graphrbac import GraphRbacManagementClient

#     # Get credentials
#     credential = DefaultAzureCredential()

#     # Initialize the GraphRbacManagementClient
#     rbac_client = GraphRbacManagementClient(credential, "<YOUR_TENANT_ID>")

#     # Get the service principal by application ID
#     sp = rbac_client.service_principals.get(principal_app_id)
    
#     return sp.object_id

# def assign_subscription_role(subscription_id: str, principal_object_id: str, role: str):
#     # Get credentials
#     credential = DefaultAzureCredential()

#     # Initialize the AuthorizationManagementClient
#     auth_client = AuthorizationManagementClient(credential, subscription_id)

#     # Find the role definition by name (this assumes that the role exists at the subscription level)
#     role_defs = list(auth_client.role_definitions.list(
#         filter=f"name eq 'Microsoft.Authorization/roleDefinitions/{role}'"
#     ))

#     if not role_defs:
#         raise ValueError(f"Role '{role}' not found")

#     role_def = role_defs[0]

#     # Assign the role
#     auth_client.role_assignments.create(
#         # role_assignment_name="",  # Generate a new GUID for each role assignment
#         scope=f"/subscriptions/{subscription_id}",
#         parameters={
#             "role_definition_id": role_def.id,
#             "principal_id": principal_object_id,
#             "principal_type": "ServicePrincipal"
#         }
#     )

# @error_handler
# def create_nsg_flowlog(network_client, nsg_id, storage_account_id):
#     flowlog_params = {
#         "target_resource_id": nsg_id,
#         "storage_id": storage_account_id,
#         "enabled": True
#     }
#     network_client.flow_logs.create_or_update(
#         "NetworkWatcherRG", "NetworkWatcher" + company_region, "default", flowlog_params
#     )



# 

from azure.identity import DefaultAzureCredential

# Constants
MICROSOFT_GRAPH_BASE_URL = "https://graph.microsoft.com/v1.0"
TENANT_ID = "<YOUR_TENANT_ID>"
ENDPOINT_APP_REGISTRATION = f"{MICROSOFT_GRAPH_BASE_URL}/myOrganization/applications"
ENDPOINT_SERVICE_PRINCIPALS = f"{MICROSOFT_GRAPH_BASE_URL}/myOrganization/servicePrincipals"
ENDPOINT_ROLE_ASSIGNMENT = f"{MICROSOFT_GRAPH_BASE_URL}/myOrganization/roleAssignments"

# Authenticating using azure-identity
credential = DefaultAzureCredential()
token = credential.get_token("https://graph.microsoft.com/.default")
headers = {
    "Authorization": f"Bearer {token.token}",
    "Content-Type": "application/json"
}

def create_cyngular_service_principal(PRINCIPAL_NAME: str):
    # Create Application
    payload = {
        "displayName": PRINCIPAL_NAME,
        "identifierUris": [f"https://{PRINCIPAL_NAME}"]
    }
    response = requests.post(ENDPOINT_APP_REGISTRATION, headers=headers, json=payload)
    app_data = response.json()

    # Create Service Principal for the Application
    sp_payload = {
        "appId": app_data["appId"]
    }
    sp_response = requests.post(ENDPOINT_SERVICE_PRINCIPALS, headers=headers, json=sp_payload)
    sp_data = sp_response.json()

    return app_data["appId"], None, TENANT_ID  # SDK doesn't return the password directly

def get_principal_object_id(principal_app_id: str) -> str:
    # Get the service principal by application ID
    response = requests.get(f"{ENDPOINT_SERVICE_PRINCIPALS}/{principal_app_id}", headers=headers)
    sp_data = response.json()
    return sp_data["id"]

def assign_subscription_role(subscription_id: str, principal_object_id: str, role: str):
    # This will be more complex as you need to get the role definition ID from the name
    # For simplicity, the below code assumes you have the role definition ID
    role_definition_id = "<ROLE_DEFINITION_ID>"

    payload = {
        "roleDefinitionId": role_definition_id,
        "principalId": principal_object_id,
        "resourceScope": f"/subscriptions/{subscription_id}"
    }
    response = requests.post(ENDPOINT_ROLE_ASSIGNMENT, headers=headers, json=payload)

    # Check if the assignment was successful
    if response.status_code != 201:
        raise ValueError(f"Failed to assign role. Error: {response.json()}")

# The create_nsg_flowlog function remains largely the same, since it's not interacting with Graph API

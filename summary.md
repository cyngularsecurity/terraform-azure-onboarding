This Terraform configuration sets up the necessary Azure resources to collect and store logs and security-related data.

Here's a breakdown of the resources and the onboarding flow:

### Onboarding Flow

The onboarding process is initiated by running the main Terraform configuration. The flow is as follows:

1.  **Initialization**: Terraform initializes the providers and modules.
2.  **Main Module**: The main tf file is the entry point. It orchestrates the deployment of other modules.
3.  **Cyngular Module**: creates the core resources for the client:
    *   A resource group to contain all the client's resources.
    *   Storage accounts in each of the client's operating locations to store logs and data.
    *   A service principal for the Cyngular application, which is granted permissions to access the created resources.
4.  **Role Assignment Module**: assigns the necessary roles to the Cyngular service principal at the management group level, granting it the required permissions to read security-related data from the client's environment.
5.  **Function Module**: deploys an Azure Function that is responsible for collecting and processing logs. The function is configured with the necessary environment variables, including the storage account connection strings and the client's locations.
6.  **Audit Logs Module**: configures the diagnostic settings to collect Azure Active Directory audit logs and sends them to the main storage account.

### Resource Categories

The created resources can be categorized as follows:

#### 1. Core Infrastructure

*   **Resource Group**: A dedicated resource group for all Cyngular-related resources.
    *   `azurerm_resource_group.cyngular_client`
*   **Storage Accounts**: Multiple storage accounts are created, one for each location the client operates in. These are used to store various logs.
    *   `azurerm_storage_account.cyngular_sa`
*   **Service Principal**: A service principal for the Cyngular application.
    *   `azuread_service_principal.client_sp`

#### 2. Logging and Monitoring

*   **Azure Function**: A serverless function to process and forward logs.
    *   `azurerm_linux_function_app.function_service`
*   **Application Insights**: For monitoring the Azure Function (optional).
    *   `azurerm_application_insights.func_azure_insights`
*   **Log Analytics Workspace**: To store logs from the Azure Function (optional).
    *   `azurerm_log_analytics_workspace.func_log_analytics`
*   **AAD Diagnostic Settings**: To export Azure AD audit logs to a storage account.
    *   `azurerm_monitor_aad_diagnostic_setting.cyngular_audit_logs`

#### 3. Identity and Access Management

*   **Role Assignments**: Assigns built-in roles to the Cyngular service principal to grant necessary permissions.
    *   `azurerm_role_assignment.role_assignment_mgmt`
*   **User Assigned Identity**: A managed identity for the Azure Function to access other Azure resources.
    *   `azurerm_user_assigned_identity.function_assignment_identity`
*   **Custom Role Definition**: A custom role is created to grant the Azure Function the specific permissions it needs.
    *   `azurerm_role_definition.function_assignment_def`

### Summary

This Terraform setup automates the process of onboarding a new client to Cyngular. It creates a secure and isolated environment for the client's data, ensuring that Cyngular has the necessary access to provide its security services while adhering to the principle of least privilege. The modular design makes it easy to manage and customize the configuration for different clients.
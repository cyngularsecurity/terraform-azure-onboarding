# Cyngular Azure Onboarding - Terraform Resources and Flow Documentation

## Overview

This document provides a comprehensive breakdown of all Terraform resources created during the Cyngular Azure onboarding process, categorized by function and purpose, along with the detailed flow of the onboarding process.

## Resource Categories

### 1. Identity and Access Management (IAM)

#### Service Principals
- **`azuread_service_principal.msgraph`** (`modules/Cyngular/ServicePrinciple.tf:1`)
  - Uses existing Microsoft Graph service principal
  - Required for accessing Microsoft Graph APIs
  
- **`azuread_service_principal.client_sp`** (`modules/Cyngular/ServicePrinciple.tf:6`)
  - Main Cyngular service principal for client access
  - Created using the provided `application_id`
  - Owned by the current user deploying the infrastructure

#### User Assigned Identity (UAI)
- **`azurerm_user_assigned_identity.function_assignment_identity`** (`modules/function/UAI.tf:1`)
  - Managed identity for the Azure Function
  - Used for automated log collection operations
  - Name format: `{client_name}-mgmt-uai`

#### Custom Role Definition
- **`azurerm_role_definition.function_assignment_def`** (`modules/function/UAI.tf:8`)
  - Custom role for function automation
  - Permissions include:
    - Resource deployments
    - Diagnostic settings management
    - Network Watcher and Flow Logs configuration
    - Virtual Network modifications
  - Scope: Management Group level

#### Role Assignments

**Service Principal Assignments:**
- **Management Group Level** (`modules/role_assignment/Main.tf:2`)
  - Multiple predefined roles assigned to service principal:
    - Reader
    - Disk Pool Operator
    - Data Operator for Managed Disks
    - Disk Snapshot Contributor
    - Microsoft Sentinel Reader
    - API Management Workspace Reader
    - Reader and Data Access
    - Managed Application Publisher Operator

**Storage Account Level:**
- **`azurerm_role_assignment.sa_contributor`** (`modules/Cyngular/StorageAccount.tf:26`)
  - Storage Account Contributor role for service principal
  - Applied to all client storage accounts
  
- **`azurerm_role_assignment.blob_owner`** (`modules/Cyngular/StorageAccount.tf:34`)
  - Storage Blob Data Owner role for service principal
  - Applied to all client storage accounts

**Function Identity Assignments:**
- **`azurerm_role_assignment.func_assigment_custom_mgmt`** (`modules/function/UAI.tf:31`)
  - Custom management role for function UAI
  - Management Group scope
  
- **`azurerm_role_assignment.func_assigment_reader_mgmt`** (`modules/function/UAI.tf:38`)
  - Reader role for function UAI
  - Management Group scope
  
- **`azurerm_role_assignment.sa_contributor`** (`modules/function/UAI.tf:45`)
  - Storage Account Contributor for function UAI
  - Applied to all storage accounts including function storage
  
- **`azurerm_role_assignment.blob_contributor`** (`modules/function/UAI.tf:53`)
  - Storage Blob Data Owner for function UAI
  - Applied to all storage accounts including function storage

### 2. Storage Infrastructure

#### Resource Group
- **`azurerm_resource_group.cyngular_client`** (`modules/Cyngular/ResourceGroup.tf:2`)
  - Central resource group for all Cyngular resources
  - Name format: `cyngular-{client_name}-rg`
  - Located in the main location

#### Client Storage Accounts
- **`azurerm_storage_account.cyngular_sa`** (`modules/Cyngular/StorageAccount.tf:1`)
  - **Multi-location deployment**: One storage account per specified location
  - **Configuration**:
    - Account Kind: StorageV2
    - Tier: Standard
    - Replication: LRS (Locally Redundant Storage)
    - TLS: Minimum version 1.2
    - Blob retention policy: Configurable days (default: 90)
  - **Naming**: `{client_name}{location}{suffix}` (max 23 characters)
  
  **Storage Account Tags by Location:**
  
  **Main Location Storage Account:**
  - `cyngular-os: true` - Operating system logs
  - `cyngular-visibility: true` - Visibility and monitoring logs
  - `cyngular-auditlogs: true/false` - Entra ID audit logs (based on `enable_audit_logs`)
  - `cyngular-activitylogs: true/false` - Subscription activity logs (based on `enable_activity_logs`)
  - `cyngular-auditevents: true/false` - Resource audit events (based on `enable_audit_events_logs`)
  - `cyngular-nsgflowlogs: true/false` - NSG flow logs (based on `enable_flow_logs`)
  - `cyngular-aks: true/false` - AKS cluster logs (based on `enable_aks_logs`)
  - `cyngular-client: {client_name}` - Client identifier
  
  **Other Location Storage Accounts:**
  - `cyngular-auditevents: true/false`
  - `cyngular-nsgflowlogs: true/false`
  - `cyngular-aks: true/false`
  - `cyngular-client: {client_name}`

#### Function Storage Account
- **`azurerm_storage_account.func_storage_account`** (`modules/function/AppRelated.tf:17`)
  - Dedicated storage for Azure Function runtime
  - Name format: `cyngularfunc{client_name}` (max 23 characters)
  - Same configuration as client storage accounts

### 3. Compute and Application Infrastructure

#### Azure Function Components

**Service Plan:**
- **`azurerm_service_plan.main`** (`modules/function/AppRelated.tf:2`)
  - Linux-based App Service Plan
  - SKU: Dynamic based on location support for Application Insights
    - `Y1` (Consumption) for locations supporting App Insights
    - `B2` (Basic) for unsupported locations (e.g., israelcentral)

**Function App:**
- **`azurerm_linux_function_app.function_service`** (`modules/function/FunctionApp.tf:1`)
  - **Runtime**: Python 3.12
  - **Deployment**: ZIP deployment from S3
  - **Identity**: User Assigned Identity (UAI)
  - **HTTPS Only**: Enforced
  - **Source**: Downloads from `https://cyngular-onboarding-templates.s3.us-east-1.amazonaws.com/azure/cyngular_func.zip`

**Function Environment Variables:**
```
AzureWebJobsDisableHomepage: true
FUNCTIONS_WORKER_RUNTIME: python
ENABLE_ORYX_BUILD: true
SCM_DO_BUILD_DURING_DEPLOYMENT: true
STORAGE_ACCOUNT_MAP: {JSON map of storage accounts}
COMPANY_LOCATIONS: {JSON array of client locations}
COMPANY_MAIN_LOCATION: {main location}
COMPANY_NAME: {client_name}
UAI_ID: {function UAI client ID}
enable_activity_logs: {boolean}
enable_audit_events_logs: {boolean}
enable_flow_logs: {boolean}
enable_aks_logs: {boolean}
```

#### Function Support Resources
- **`local_sensitive_file.zip_file`** (`modules/function/Data.tf:16`)
  - Downloads and stores function code locally
  - Base64 encoded ZIP file from S3

### 4. Monitoring and Logging Infrastructure

#### Log Analytics (Optional)
- **`azurerm_log_analytics_workspace.func_log_analytics`** (`modules/function/AppRelated.tf:33`)
  - **Created when**: `allow_function_logging = true`
  - SKU: PerGB2018
  - Retention: 30 days
  - Purpose: Function application logging

#### Application Insights (Optional)
- **`azurerm_application_insights.func_azure_insights`** (`modules/function/AppRelated.tf:48`)
  - **Created when**: `allow_function_logging = true`
  - Type: other
  - Retention: 60 days
  - Linked to Log Analytics workspace

#### Entra ID Audit Logs
- **`azurerm_monitor_aad_diagnostic_setting.cyngular_audit_logs`** (`modules/audit_logs/Main.tf:1`)
  - **Created when**: `enable_audit_logs = true`
  - **Target**: Main location storage account
  - **Log Categories**:
    - AuditLogs, SignInLogs, NonInteractiveUserSignInLogs
    - ServicePrincipalSignInLogs, ManagedIdentitySignInLogs
    - ProvisioningLogs, ADFSSignInLogs
    - NetworkAccessTrafficLogs, EnrichedOffice365AuditLogs
    - MicrosoftGraphActivityLogs, RemoteNetworkHealthLogs
    - UserRiskEvents, ServicePrincipalRiskEvents
    - RiskyUsers, RiskyServicePrincipals, NetworkAccessAlerts

### 5. External Data Sources

#### HTTP Data Source
- **`data.http.zip_file`** (`modules/function/Data.tf:1`)
  - Downloads function code from S3
  - Validates 200 status code response

#### Azure AD Configuration
- **`data.azuread_client_config.current`** (referenced in locals)
  - Gets current user and tenant information
  - Used for setting resource ownership and management group scope

#### Microsoft Graph App ID
- **`data.azuread_application_published_app_ids.well_known`** (referenced in main.tf:13)
  - Gets Microsoft Graph application ID
  - Used for service principal creation

## Onboarding Process Flow

### Phase 1: Pre-Deployment Preparation

1. **Prerequisites Validation**
   - Azure CLI authentication (`az login`)
   - Terraform CLI installation (v1.9.5+)
   - Azure subscription access
   - Management Group permissions

2. **Configuration Setup**
   - Client-specific `.tfvars` file creation
   - Application ID provisioning (multi-tenant app)
   - Location selection and validation
   - Log collection parameters decision

### Phase 2: Core Infrastructure Deployment

1. **Resource Group Creation**
   - Central resource group in main location
   - Tagged with Cyngular vendor identification

2. **Identity Infrastructure**
   - Service principal creation using provided application ID
   - Microsoft Graph service principal reference
   - User Assigned Identity for function automation

3. **Storage Infrastructure**
   - Multi-location storage account deployment
   - Location-specific tagging based on log collection preferences
   - Blob retention policy configuration
   - Function-specific storage account

### Phase 3: Access Control Configuration

1. **Role Definition Creation**
   - Custom management role for function automation
   - Scoped to management group level

2. **Service Principal Role Assignments**
   - Management group level: 8 predefined roles
   - Storage account level: Contributor and Blob Owner roles

3. **Function Identity Role Assignments**
   - Management group level: Custom role and Reader
   - Storage account level: Contributor and Blob Owner for all accounts

### Phase 4: Function Deployment

1. **Function Code Acquisition**
   - Download from S3 bucket
   - Local ZIP file creation
   - Validation of download success

2. **Supporting Infrastructure**
   - App Service Plan creation (location-dependent SKU)
   - Optional Log Analytics workspace
   - Optional Application Insights

3. **Function App Deployment**
   - ZIP deployment with Python 3.12 runtime
   - Environment variable configuration
   - UAI assignment
   - Application Insights integration (if enabled)

### Phase 5: Log Collection Configuration

1. **Entra ID Audit Logs** (if enabled)
   - Diagnostic settings creation
   - 18 log categories enabled
   - Export to main location storage account

2. **Other Log Types** (Function-managed)
   - Activity logs (subscription level)
   - Audit events (resource level)
   - NSG flow logs
   - AKS cluster logs

### Phase 6: Post-Deployment Configuration

1. **Admin Consent Process**
   - Terraform outputs admin consent URL
   - Manual admin consent required for service principal
   - Grants necessary API permissions

2. **Validation and Testing**
   - Resource deployment verification
   - Permission validation
   - Function operation testing

## Resource Dependencies

### Critical Dependencies

1. **Storage Accounts** → **Role Assignments**
   - Storage accounts must exist before role assignments
   - Function depends on all storage account role assignments

2. **UAI** → **Role Definition** → **Role Assignments** → **Function**
   - User Assigned Identity creation
   - Custom role definition
   - Role assignments to UAI
   - Function deployment with UAI

3. **ZIP File** → **Function Deployment**
   - Function code must be downloaded before deployment
   - Local ZIP file creation required

### Optional Dependencies

1. **Log Analytics** → **Application Insights**
   - Log Analytics workspace required for Application Insights
   - Both required for function logging

2. **Audit Logs Module** ← **Main Storage Account**
   - Audit logs diagnostic settings depend on main storage account
   - Only created when `enable_audit_logs = true`

## Security Considerations

### Least Privilege Access
- Service principal assigned only necessary roles
- Function UAI has limited custom role permissions
- Storage access scoped to specific accounts

### Data Protection
- TLS 1.2 minimum for all storage accounts
- HTTPS enforced for function app
- Blob retention policies configured

### Monitoring and Auditing
- Comprehensive log collection across multiple categories
- Optional Application Insights for function monitoring
- Centralized storage for audit trails

## Terraform State Management

### Workspace Strategy
- Client-specific workspaces (`ob-{client_name}`)
- Isolated state per client deployment
- State files in `terraform.tfstate.d/{workspace}/`

### State Backup
- Manual state backup recommended for non-remote backends
- Commands: `terraform state pull > cyngular_onboarding.tfstate`
- Restore: `terraform state push cyngular_onboarding.tfstate`

## Common Operational Patterns

### Function Code Updates
```bash
terraform taint "module.cyngular_function.azurerm_linux_function_app.function_service"
terraform apply --auto-approve
```

### Storage Account Issues
```bash
# If storage account creation fails
terraform taint random_string.suffix
# or
terraform state rm module.onboarding.random_string.suffix
```

### Client-Specific Deployment
```bash
terraform workspace select ob-{client_name}
terraform apply -var-file="tfvars/{client_name}.tfvars"
```

This infrastructure provides a comprehensive, secure, and automated solution for onboarding clients to Cyngular's security monitoring platform, with extensive logging capabilities and proper access controls.
# Overview

Terraform-based Azure onboarding infrastructure for log collection. deploys Azure resources to enable security log collection across multiple Azure locations for client organizations.

## Architecture

The infrastructure is organized into modules:

- **Main Module** (`modules/Cyngular/`): Core Cyngular infrastructure including resource group, storage accounts, service principal.
- **Function Module** (`modules/function/`): Azure Function App for log processing and collection automation
- **Role Assignment Module** (`modules/role_assignment/`): RBAC role assignments for the service principal across management groups
- **Audit Logs Module** (`modules/audit_logs/`): Entra ID audit log configuration and export

### Key Components

1. **Multi-location Storage Accounts**: Created across specified Azure locations for log storage
2. **Service Principal**: Cross tenant application & Service principle relationship for viewing client resources
3. **Azure Function**: Automated log collection and processing
4. **Diagnostic Settings**: Configurable log collection for various Azure services

- Using Centralized storage account:
  - Audit Logs (Entra)
  - Activity Logs (Subscriptions)

- Using storage account Per location:
  - NSG Flow Logs
  - AKS Logs
  - Audit Event Logs (variable resoucres)

## Common Development Commands

### Prerequisites Validation

**CRITICAL: ALWAYS run validation before Terraform operations**

```bash
# Validate all prerequisites before starting
./Scripts/validate_prerequisites.sh tfvars/{client}.tfvars

# Register required Azure Resource Providers (if validation fails)
bash /tmp/register_azure_providers.sh
```

The validation script checks:
- Required CLI tools (Terraform, Azure CLI, curl, git)
- Terraform version compatibility (>= 1.9.5)
- Azure CLI authentication
- Azure Resource Provider registration
- Management group access
- Required permissions
- Terraform configuration and variables

### Terraform Operations

```bash
# Initialize and upgrade providers
terraform init -upgrade

# Plan deployment for specific client (dev mode, as in prod will use the tf module published in terraform module regitrey, as described in project readme)
terraform plan -var-file="tfvars/{client}.tfvars"

# Apply configuration
terraform apply -var-file="tfvars/{client}.tfvars" --auto-approve

# Taint and redeploy function with updated code
terraform taint "module.cyngular_function.azurerm_linux_function_app.function_service"
terraform apply --auto-approve
```

### State Management

```bash
# Save state for backup (when not using remote backend)
terraform state pull > cyngular_onboarding.tfstate

# Restore state
terraform state push cyngular_onboarding.tfstate

# Remove problematic resources from state
terraform state rm module.onboarding.random_string.suffix
```

## Key Project Configuration

### Terraform Version Requirements

- Terraform CLI version 1.9.5 or compatible as specified in release 3.3
- Azure CLI required for authentication

### Required Variables

- `client_name`: Lowercase alphanumeric company identifier
- `application_id`: UUID for the multi-tenant service principal
- `main_subscription_id`: Azure subscription for deployment
- `locations`: List of Azure regions for resource deployment

### Log Collection Toggles

- `enable_audit_logs`: Entra ID audit logs (default: true)
- `enable_activity_logs`: Subscription activity logs (default: true)
- `enable_audit_events_logs`: Resource diagnostic settings (default: true)
- `enable_flow_logs`: NSG flow logs (default: true)
- `enable_aks_logs`: AKS cluster logs (default: true)

### Common Issues and Solutions

- **Storage Account Creation Errors**: Taint the random suffix if encountering ParentResourceNotFound errors
- **Service Principal Issues**: Delete existing SP if it was created before Terraform apply
- **Diagnostic Settings Limit**: Maximum 5 diagnostic settings per subscription
- **App Insights Locations**: Some regions like `israelcentral` don't support Application Insights

### Authentication Flow

1. Run prerequisites validation: `./Scripts/validate_prerequisites.sh tfvars/{client}.tfvars`
2. Run `az login` for Azure authentication (if not already authenticated)
3. Register required Azure Resource Providers (if needed): `bash /tmp/register_azure_providers.sh`
4. Deploy Terraform infrastructure
5. Use output admin consent URL to grant permissions
6. Service principal gets assigned predefined roles across management group scope

## Storage Account Tagging

Different log types require specific storage account tags:

- `cyngular-auditlogs: "true"` - Entra Audit Logs
- `cyngular-activitylogs: "true"` - Subscription Activity Logs  
- `cyngular-auditevents: "true"` - Resource Diagnostic Settings
- `cyngular-nsgflowlogs: "true"` - NSG Flow Logs
- `cyngular-aks: "true"` - AKS Cluster Logs

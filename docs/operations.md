# Operations Guide

This document covers common operational tasks for maintaining and updating the Azure onboarding infrastructure.

## Function App Operations

### Redeploying Function with Updated Code

To redeploy the Azure Function App with the latest code changes:

```bash
terraform taint "module.cyngular_function.azurerm_linux_function_app.function_service"
terraform apply --auto-approve
```

This operation will:
1. Mark the function app resource for recreation
2. Download the latest function code package
3. Redeploy the function app with the updated code

**Note**: The function app will experience brief downtime during redeployment.

## Terraform Operations

### Standard Deployment Workflow

```bash
# Initialize and upgrade providers
terraform init -upgrade

# Review planned changes
terraform plan -var-file="tfvars/{client}.tfvars"

# Apply configuration
terraform apply -var-file="tfvars/{client}.tfvars" --auto-approve
```

### State Management Operations

```bash
# View current state
terraform state list

# Save state backup
terraform state pull > cyngular_onboarding.tfstate

# Restore from backup
terraform state push cyngular_onboarding.tfstate

# Remove specific resource from state
terraform state rm <resource_address>
```

### Resource Tainting

Tainting forces Terraform to recreate a resource on the next apply:

```bash
# Taint function app
terraform taint "module.cyngular_function.azurerm_linux_function_app.function_service"

# Taint storage account suffix
terraform taint "random_string.suffix"

# Taint specific module resource
terraform taint "module.onboarding.<resource_type>.<resource_name>"
```

## Validation and Testing

### Pre-Deployment Validation

```bash
# Validate Terraform configuration
terraform validate

# Format Terraform files
terraform fmt -recursive

# Generate and review plan
terraform plan -out=tfplan
```

### Post-Deployment Verification

```bash
# Verify resource group creation
az group show --name cyngular-{client_name}-rg

# Check storage accounts
az storage account list --resource-group cyngular-{client_name}-rg --output table

# Verify function app status
az functionapp show --name cyngular-func-{client_name} --resource-group cyngular-{client_name}-rg

# Check diagnostic settings
az monitor diagnostic-settings subscription list --subscription {subscription_id}
```

## Troubleshooting Operations

### Forced Resource Recreation

If a resource is in a bad state:

```bash
# Remove from state and recreate
terraform state rm <resource_address>
terraform apply --auto-approve
```

### Provider Cache Clear

If experiencing provider issues:

```bash
# Clear provider cache
rm -rf .terraform
rm .terraform.lock.hcl

# Reinitialize
terraform init -upgrade
```

## References

- [Azure Portal Safelist URLs](https://learn.microsoft.com/en-us/azure/azure-portal/azure-portal-safelist-urls?tabs=public-cloud)
- [Terraform State Command](https://developer.hashicorp.com/terraform/cli/commands/state)
- [Azure CLI Reference](https://learn.microsoft.com/en-us/cli/azure/reference-index)

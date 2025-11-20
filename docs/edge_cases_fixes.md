# Edge Cases and Troubleshooting

This document provides solutions to common issues and edge cases encountered during Azure onboarding deployment.

## Important Notices

### Location Selection
**Note**: Only select Israel (`israelcentral`) as your main deployment location if absolutely necessary, as this may result in higher costs for Function App service plans due to regional pricing differences.

### Terraform Version Requirements
- Terraform CLI version `1.9.5` or compatible as specified in release `3.3`
- Azure CLI is required for authentication

### Resource Limits
- **Diagnostic Settings Limit**: Maximum of 5 diagnostic settings per subscription. Ensure you do not exceed this limit when enabling log collection.

### State Management (Non-Remote Backend)
If not using a remote Terraform backend, save your Terraform state for future management:

```bash
# Save state
terraform state pull > cyngular_onboarding.tfstate

# Restore state
terraform state push cyngular_onboarding.tfstate
```

## Common Issues and Solutions

### Storage Account Creation Errors

**Issue**: `ParentResourceNotFound` error when creating Cyngular storage accounts.

**Error Message**:
```
unexpected status 404 (404 Not Found) with error: ParentResourceNotFound:
Failed to perform 'read' on resource(s) of type 'storageAccounts/blobServices',
because the parent resource '/subscriptions/{subscription_id}/resourceGroups/cyngular-{client_name}-rg/providers/Microsoft.Storage/storageAccounts/{storage_account_name}' could not be found.
```

**Solution**: Taint the storage account suffix resource and reapply:
```bash
terraform taint random_string.suffix
# OR
terraform state rm module.onboarding.random_string.suffix
terraform apply --auto-approve
```

### Service Principal Creation Issues

**Issue**: Service Principal resource creation takes too long or times out.

**Possible Cause**: The provided `application_id` might be invalid.

**Solution**: Verify the application ID is correct and exists in your Azure AD tenant.

### Resource Provider Registration Errors

**Error Message**:
```
Resource provider(s): Microsoft.Storage are not registered for subscription
and you don't have permissions to register a resource provider
```

**Solution**: Ensure your user account has the necessary permissions to register resource providers, or contact your Azure administrator to register the `Microsoft.Storage` resource provider for your subscription.

### Authorization Errors

**Error Message**:
```
The client 'user@company.com' with object id 'xxx' does not have authorization
to perform action 'microsoft.storage/register/action' over scope '/subscriptions/xxx'
or the scope is invalid. If access was recently granted, please refresh your credentials.
```

**Solution**:
1. Verify you have the required permissions (see README Step 2)
2. If access was recently granted, refresh your Azure credentials:
   ```bash
   az logout
   az login
   ```

### Duplicate Diagnostic Settings

**Issue**: Terraform state conflict with existing resources.

**Error Message**:
```
Error: A resource with the ID "/providers/Microsoft.AADIAM/diagnosticSettings/cyngular-audit-logs-{client}"
already exists - to be managed via Terraform this resource needs to be imported into the State.
```

**Cause**: This is typically due to a stale or transient response from the Azure provider.

**Solution**: Import the existing resource into Terraform state:
```bash
terraform import azurerm_monitor_aad_diagnostic_setting.audit_logs "/providers/Microsoft.AADIAM/diagnosticSettings/cyngular-audit-logs-{client}"
```

## References

- [Azure CLI Documentation][azure_cli]
- [Terraform CLI Installation][terraform_cli]
- [Elevate Access for Global Administrator][azure_docs_url_1]

[terraform_cli]: https://developer.hashicorp.com/terraform/install
[azure_cli]: https://learn.microsoft.com/en-us/cli/azure
[azure_docs_url_1]: https://learn.microsoft.com/en-us/azure/role-based-access-control/elevate-access-global-admin?tabs=azure-portal,entra-audit-logs#step-1-elevate-access-for-a-global-administrator

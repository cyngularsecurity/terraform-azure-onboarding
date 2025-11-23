# Edge Cases and Troubleshooting

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


### auto service provider Registration attempts with access errors

- tldr: make sure you have sufficient permissions as required in docs
- running terraform plan get stuck or ahowing the folowing err:

```shell
terraform plan
^C
Interrupt received.
Please wait for Terraform to exit or data loss may occur.
Gracefully shutting down...

Stopping operation...

Error: Encountered an error whilst ensuring Resource Providers are registered.
Terraform automatically attempts to register the Azure Resource Providers it supports, to
ensure it is able to provision resources.
If you don't have permission to register Resource Providers you may wish to disable this
functionality ...

│ waiting for Subscription Provider (Subscription: "xxxxxxxxxxxxxxxxxxxxxxxx"
│ Provider Name: "Microsoft.DataProtection") to be registered: context canceled
│
│   with module.onboarding.provider["registry.terraform.io/hashicorp/azurerm"],
│   on .terraform/modules/onboarding/providers.tf line 27, in provider "azurerm":
│   27: provider "azurerm" {
'''

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

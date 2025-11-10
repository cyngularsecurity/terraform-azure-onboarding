
## Notice

- **Note on Location Selection**: Only select Israel as your main deployment location if absolutely necessary, as this may result in higher costs for Function App service plans.
- If not using a remote terraform backend, save terraform state for future managment, Run ```terraform state pull > cyngular_onboarding.tfstate``` .
- To reuse it, Run ```terraform state push cyngular_onboarding.tfstate``` .

<!-- - To Rreinstall / Update 'cyngular_func.zip', Run ```terraform taint "module.cyngular_function.null_resource.get_zip"``` & re run terraform apply -->

- Terraform Cli version required is '1.9.5' as of release '3.3'
- Make sure not to reach The limit of 5 diagnostic settings per subscription account

- If Service principle resource, takes too long to create, app id might be invalid.
- If encountering an error for creating cyngular Storage accounts: "unexpected status 404 (404 Not Found) with error: ParentResourceNotFound: Failed to perform 'read' on resource(s) of type 'storageAccounts/blobServices', because the parent resource '/subscriptions/{subscription_id}/resourceGroups/cyngular-{client_name}-rg/providers/Microsoft.Storage/storageAccounts/{storage_account_name}' could not be found." - taint the storage account suffix, and apply again: ```terraform taint random_string.suffix``` or ```terraform state rm module.onboarding.random_string.suffix```.

<!-- - If Service principle resource, seems to already exist, find it and delete it, as visiting the admin consent url prior to terraform apply will create the sp. -->

[terraform_cli]: https://developer.hashicorp.com/terraform/install
[azure_cli]: https://learn.microsoft.com/en-us/cli/azure
[curl_cli]: https://developers.greenwayhealth.com/developer-platform/docs/installing-curl
[git_cli]: https://git-scm.com/

[azure_docs_url_1]: https://learn.microsoft.com/en-us/azure/role-based-access-control/elevate-access-global-admin?tabs=azure-portal,entra-audit-logs#step-1-elevate-access-for-a-global-administrator

<!-- [azure_func_cli]: https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=macos,isolated-process,node-v4,python-v2,http-trigger,container-apps&pivots=programming-language-python -->




Resource provider(s): Microsoft.Storage are not registered for subscription Azure subscription 1 and you don’t have permissions to register a resource provider for subscription Azure subscription 1


The client 'this@company.com' with object id 'xxxxxxxxxxxxxxxxxxxxxxx' does not have authorization to perform action 'microsoft.storage/register/action' over scope '/subscriptions/xxxxxxxxxxxxxxxxxxxxxxx' or the scope is invalid. If access was recently granted, please refresh your credentials

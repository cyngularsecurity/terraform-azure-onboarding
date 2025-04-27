# Azure Deployment Instructions for Cyngular Platform

**Prerequisites:**

- [Terraform CLI][terraform_cli]
- [Azure CLI][azure_cli]
- [Curl][curl_cli]
- [Git][git_cli]

**Step 1:** Ensure the Management Groups feature is enabled in your Azure subscription.

**Step 2:** Set Required Permissions  
   Ensure your Azure user has the following permission:

- `Microsoft.Authorization/roleAssignments/write` over the management group scope, (path `/providers/Microsoft.Management/managementGroups/{root management group ID}`).
- `Microsoft.Authorization/roleAssignments/contributor`
   over each Subscription scope, (path `/subscriptions/{subscription ID}`).
   or over each Management Group scope, (path `/providers/Microsoft.Management/managementGroups/{management group ID}`).

- Make sure the user has access to the Root Management Group
   validate with command:
   ```bash
   az account management-group show --name $(az account show --query tenantId -o tsv)
   ```
- Make sure the user has access to assign roles in Root Management Group Scope - ([Elevate access for a Global Administrator][azure_docs_url_1])

**Step 3:** Configure Optional Log Collection Parameters  

- Before creating the `main.tf` file, decide which log types you want to enable:
- a. **If the service (e.g., NSGs Flow Logs) isn't enabled and you want to enable it,** leave the parameter (e.g., enable_flow_logs) as `true` — no further action is needed.
- b. **If the service is already enabled or you don't want to enable it (e.g., Entra Audit Logs),** set the parameter to `false`. Add the tag to the Storage Account only if your company is already collecting the logs and wants Cyngular to analyze them.

**Log Type Parameters and Required Tags:**

- **Entra Audit Logs:** `{key: "cyngular-auditlogs", value: "true"}`
- **Subscriptions Diagnostic Settings:** `{key: "cyngular-activitylogs", value: "true"}`
- **Resource Diagnostic Settings:** `{key: "cyngular-auditevents", value: "true"}`
- **NSGs Flow Logs:** `{key: "cyngular-nsgflowlogs", value: "true"}`
- **AKS Cluster Diagnostic Settings:** `{key: "cyngular-aks", value: "true"}`

**Step 4:** Create `main.tf` File  
   After deciding on the log collection parameters, create a `main.tf` file with the following content, replacing the placeholders with your actual values:

   ```hcl
   module "onboarding" {
      source  = "cyngularsecurity/onboarding/azure"

      main_subscription_id = "<deployment_subscription_id>"

      application_id = "<application_id>"
      client_name    = "<company_name>"
      locations      = ["<location1>", "<location2>"]

      root_management_group_name = "<root_management_group_name>"

      enable_audit_logs          = true
      enable_activity_logs       = true
      enable_aks_logs            = true
      enable_audit_events_logs   = true
      enable_flow_logs           = true
   }

   output "admin_consent_url" {
      description = "Admin Consent URL"
      value = module.onboarding.org_admin_consent_url
   }
   ```

**Step 5:** Authenticate with Azure  
   Run `az login`.  
   This command will open a browser window for you to log in with your Azure credentials.
   Once authenticated, close the browser tab.
   Choose the subscription to set as default.

**Step 6:** Initialize and Apply Terraform  
   Run the following Terraform commands in the same directory as the `main.tf` file:
  
  ```bash
  terraform init -upgrade
  terraform plan
  terraform apply --auto-approve
  ```

<!-- **Step 6:** Export Audit Logs
   If audit logs are already configured, tag the storage account accordingly. [Refer to Step 3]  
   If enable_audit_logs is set to true, export Entra ID (AAD) diagnostic settings to the appropriately tagged storage account, specifying all log categories. (https://github.com/MicrosoftDocs/entra-docs/blob/main/docs/identity/monitoring-health/media/howto-configure-diagnostic-settings/diagnostic-settings-start.png) -->

**Step 7:** Grant Admin Consent  
   The Terraform output will include an admin consent URL link. Open it and grant admin consent.

   <!-- In Entra ID, Navigate to Enterprise applications
   Remove the filter for Enterprise Application on Application type
   Find the Application by name "{Client Name} SP"
   click on Permissions under the Security section, and Grant Admin Consent for Default Directory -->

<!-- # to redeploy the function with upto date zip code:

```bash
terraform taint "module.cyngular_function.azurerm_linux_function_app.function_service"
terraform apply --auto-approve
``` -->

<!-- https://registry.terraform.io/modules/cyngularsecurity/onboarding/azure/latest -->

<!-- https://learn.microsoft.com/en-us/azure/azure-portal/azure-portal-safelist-urls?tabs=public-cloud -->

## Notice

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

[azure_func_cli]: https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=macos,isolated-process,node-v4,python-v2,http-trigger,container-apps&pivots=programming-language-python
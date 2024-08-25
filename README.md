### Azure Deployment Instructions for Cyngular Platform

**Prerequisites:** Install CLI Tools

- Terraform CLI [https://developer.hashicorp.com/terraform/install]
- Azure CLI [https://learn.microsoft.com/en-us/cli/azure/]
- Curl [https://developers.greenwayhealth.com/developer-platform/docs/installing-curl]

**Step 2:** Ensure the Management Groups feature is enabled in your Azure subscription.

**Step 3:** Set Required Permissions  
   Ensure your Azure user has the following permission:

- `Microsoft.Authorization/roleAssignments/write` over the path `/providers/Microsoft.Management/managementGroups/{root management group ID}`.

**Step 4:** Configure Optional Log Collection Parameters  
   Before creating the `main.tf` file, decide which log types you want to enable:

   a. **If the service (e.g., NSGs Flow Logs) isn't enabled and you want to enable it,** leave the parameter (e.g., enable_flow_logs as `true` — no further action is needed.
   b. **If the service is already enabled or you don't want to enable it (e.g., Entra Audit Logs),** set the parameter to `false`. Add the tag to the Storage Account only if your company is already collecting the logs and wants Cyngular to analyze them.

   **Log Type Parameters and Required Tags:**

- **Entra Audit Logs:** `{key: "cyngular-auditlogs", value: "true"}`
- **Subscriptions Diagnostic Settings:** `{key: "cyngular-activitylogs", value: "true"}`
- **Resource Diagnostic Settings:** `{key: "cyngular-auditevents", value: "true"}`
- **NSGs Flow Logs:** `{key: "cyngular-nsgflowlogs", value: "true"}`
- **AKS Cluster Diagnostic Settings:** `{key: "cyngular-aks", value: "true"}`

**Step 5:** Create `main.tf` File  
   After deciding on the log collection parameters, create a `main.tf` file with the following content, replacing the placeholders with your actual values:

   ```hcl
   module "onboarding" {
      source  = "cyngularsecurity/onboarding/azure"
      version = "3.0.57"
      application_id = "<application_id>"
      client_name    = "<company_name>"
      locations      = ["<location1>", "<location2>"]

      enable_activity_logs       = true
      enable_aks_logs            = true
      enable_audit_events_logs   = true
      enable_audit_logs          = true
      enable_flow_logs           = true
   }
   ```

**Step 6:** Authenticate with Azure  
   Run `az login`.  
   This command will open a browser window for you to log in with your Azure credentials. Once authenticated, close the browser tab.

**Step 7:** Initialize and Apply Terraform  
   Run the following Terraform commands in the same directory as the `main.tf` file:
  
  ```bash
  terraform init
  terraform plan
  terraform apply --auto-approve
  ```

<!-- # to redeploy the function with upto date zip code:

```bash
terraform taint "module.cyngular_function.azurerm_linux_function_app.function_service"
terraform apply --auto-approve
``` -->

<!-- https://registry.terraform.io/modules/cyngularsecurity/onboarding/azure/latest -->

<!-- https://learn.microsoft.com/en-us/azure/azure-portal/azure-portal-safelist-urls?tabs=public-cloud -->
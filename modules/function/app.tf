
resource "azurerm_linux_function_app" "function_service" {
  name                = local.func_name
  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  https_only                    = true
  public_network_access_enabled = true

  service_plan_id            = azurerm_service_plan.regular.id
  storage_account_name       = azurerm_storage_account.func_storage_account.name
  storage_account_access_key = azurerm_storage_account.func_storage_account.primary_access_key

  # zip_deploy_file = data.http.function_zip.response_body
  # zip_deploy_file = data.archive_file.function_app_zip.output_path
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function_assignment_identity.id]
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    # "FUNCTIONS_EXTENSION_VERSION" = "~4"

    "ENABLE_ORYX_BUILD" = true
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = true

    # "WEBSITE_RUN_FROM_PACKAGE" = "https://devsitesawestus2.blob.core.windows.net/cyngular-client-function/cyngular_func.zip"
    "WEBSITE_RUN_FROM_PACKAGE" = "https://westus2sitesadev.blob.core.windows.net/cyngular-ob/cyngular_func.zip?se=2026-08-04T13%3A44Z&sp=r&spr=https&sv=2022-11-02&sr=b&sig=e26fEfpVgib%2BU0VqBzwuECng9uah8AqlnMTtwpPyxm4%3D"
    
    # "WEBSITE_RUN_FROM_PACKAGE" = "https://cyngular-onboarding-templates.s3.amazonaws.com/azure/cyngular_func.zip"
    # "WEBSITE_RUN_FROM_PACKAGE" = "1"

    "STORAGE_ACCOUNT_MAPPINGS" = jsonencode(var.default_storage_accounts)
    "COMPANY_LOCATIONS"        = jsonencode(var.client_locations)
    "ROOT_MGMT_GROUP_ID"       = local.mgmt_group_id
    "UAI_ID"                   = azurerm_user_assigned_identity.function_assignment_identity.client_id
    "enable_activity_logs"     = var.enable_activity_logs
    "enable_audit_events_logs" = var.enable_audit_events_logs
    "enable_flow_logs"         = var.enable_flow_logs
    "enable_aks_logs"          = var.enable_aks_logs
  }

  site_config {
    application_insights_connection_string = azurerm_application_insights.func_azure_insights.connection_string
    application_insights_key               = azurerm_application_insights.func_azure_insights.instrumentation_key
    application_stack {
      python_version = "3.11"
    }
    # app_command_line = <<-EOF
    #   #!/bin/bash
    #   echo "${local.function_app_zip_content}" | base64 --decode > /home/site/wwwroot/function_app.zip
    #   unzip /home/site/wwwroot/function_app.zip -d /home/site/wwwroot
    # EOF
  }
  tags = var.tags
  lifecycle {
    ignore_changes = [
      # app_settings,
      tags
    ]
  }
}

# resource "azurerm_function_app_function" "example" {
#   name            = "cyngular-function-app-function"
#   function_app_id = azurerm_linux_function_app.function_service.id
#   language        = "Python"

#   file {
#     name    = "run.csx"
#     content = file("exampledata/run.csx")
#   }

#   test_data = jsonencode({
#     "name" = "Azure"
#   })
#   config_json = jsonencode({
#     "bindings" = [
#       {
#         "authLevel" = "function"
#         "direction" = "in"
#         "methods" = [
#           "get",
#           "post",
#         ]
#         "name" = "req"
#         "type" = "httpTrigger"
#       },
#       {
#         "direction" = "out"
#         "name"      = "$return"
#         "type"      = "http"
#       },
#     ]
#   })
# }


resource "azurerm_linux_function_app" "function_service" {
  name                = local.func_name
  resource_group_name = var.cyngular_rg_name
  location            = var.override_location != "" ? var.override_location : var.main_location

  # always_on                                     = false
  https_only                    = true
  public_network_access_enabled = true

  service_plan_id            = azurerm_service_plan.regular.id
  storage_account_name       = azurerm_storage_account.func_storage_account.name
  storage_account_access_key = azurerm_storage_account.func_storage_account.primary_access_key

  zip_deploy_file = local.zip_file_path

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function_assignment_identity.id]
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"    = "python"
    "AzureWebJobsDisableHomepage" = true

    "ENABLE_ORYX_BUILD"              = true
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = true

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
  depends_on = [
    null_resource.get_zip
  ]
}
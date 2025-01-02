
resource "azurerm_linux_function_app" "function_service" {
  name                = local.func_name
  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  https_only                    = true

  service_plan_id            = azurerm_service_plan.main.id
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

    "UAI_ID"                   = azurerm_user_assigned_identity.function_assignment_identity.client_id

    "ROOT_MGMT_GROUP_ID"       = local.mgmt_group_id
    "enable_activity_logs"     = var.enable_activity_logs
    "enable_audit_events_logs" = var.enable_audit_events_logs
    "enable_flow_logs"         = var.enable_flow_logs
    "enable_aks_logs"          = var.enable_aks_logs
  }

  site_config {
    application_insights_connection_string = try(azurerm_application_insights.func_azure_insights[0].connection_string, null)
    application_insights_key               = try(azurerm_application_insights.func_azure_insights[0].instrumentation_key, null)

    application_stack {
      python_version = "3.12"
    }
  }
  
  tags = var.tags
  depends_on = [
    local_sensitive_file.zip_file
  ]
}
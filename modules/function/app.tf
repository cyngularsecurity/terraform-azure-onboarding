
resource "azurerm_linux_function_app" "function_service" {
  name                = "cyngular-app-${var.client_name}"
  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  https_only                    = true
  public_network_access_enabled = true

  service_plan_id            = azurerm_service_plan.regular.id
  storage_account_name       = azurerm_storage_account.func_storage_account.name
  storage_account_access_key = azurerm_storage_account.func_storage_account.primary_access_key

  zip_deploy_file = var.service_zip
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function_assignment_identity.id]
  }

  app_settings = {
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = true,
    # "FUNCTIONS_EXTENSION_VERSION" = "~4",
    "FUNCTIONS_WORKER_RUNTIME" = "python",
    "WEBSITE_RUN_FROM_PACKAGE" = "https://cyngular-onboarding-templates.s3.amazonaws.com/azure/func_zip.zip"

    "STORAGE_ACCOUNT_MAPPINGS" = jsonencode(var.default_storage_accounts),
    "COMPANY_LOCATIONS"        = jsonencode(var.client_locations),
    "ROOT_MGMT_GROUP_ID"       = local.mgmt_group_id,
    "UAI_ID"                   = azurerm_user_assigned_identity.function_assignment_identity.client_id,

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
  }

  lifecycle {
    ignore_changes = [
      # app_settings,
      tags
    ]
  }
  tags = var.tags
}
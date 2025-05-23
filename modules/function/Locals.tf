
locals {

  mgmt_group_id = var.mgmt_group_id
  func_name     = "cyngular-func-${var.client_name}-${var.suffix}"

  func_sp_sku_name = contains(var.app_insights_unsupported_locations, var.main_location) ? "B2" : "Y1"

  func_zip_url = "https://cyngular-onboarding-templates.s3.us-east-1.amazonaws.com/azure/cyngular_func.zip"

  zip_file_path = "${path.root}/cyngular_func.zip"

  func_env_vars = {
    "AzureWebJobsDisableHomepage" = true

    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "ENABLE_ORYX_BUILD"              = true
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = true

    "STORAGE_ACCOUNT_MAP"   = jsonencode(var.default_storage_accounts)
    "COMPANY_LOCATIONS"     = jsonencode(var.client_locations)
    "COMPANY_MAIN_LOCATION" = var.main_location

    "COMPANY_NAME" = var.client_name
    "UAI_ID"       = azurerm_user_assigned_identity.function_assignment_identity.client_id

    "enable_activity_logs"     = var.enable_activity_logs
    "enable_audit_events_logs" = var.enable_audit_events_logs
    "enable_flow_logs"         = var.enable_flow_logs
    "enable_aks_logs"          = var.enable_aks_logs
  }
}
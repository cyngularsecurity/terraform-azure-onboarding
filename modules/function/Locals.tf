
locals {

  mgmt_group_id = var.mgmt_group_id
  func_name     = "cyngular-func-${var.client_name}-${var.suffix}"

  func_sp_sku_name = contains(var.app_insights_unsupported_locations, var.main_location) ? "B2" : "Y1"

  func_zip_url = "https://cyngular-onboarding-templates.s3.us-east-1.amazonaws.com/azure/cyngular_func.zip"

  zip_file_path = "${path.root}/cyngular_func.zip"

  # deploy_script_path = "${path.module}/DeployFunctionCode.sh"

  # deploy_script_env = {
  #   ZIP_BLOB_URL     =  local.func_zip_url
  #   ZIP_FILE_PATH     = local.zip_file_path

  #   SUBSCRIPTION_ID = var.main_subscription_id
  #   RESOURCE_GROUP  = var.cyngular_rg_name
  #   FUNCTION_APP_NAME = local.func_name
  # }

  # sync_triggers_command = "az rest --method post --url \"https://management.azure.com/subscriptions/${var.main_subscription_id}/resourceGroups/${var.cyngular_rg_name}/providers/Microsoft.Web/sites/${local.func_name}/syncfunctiontriggers?api-version=2016-08-01\""

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

    # "fake_subs_n"              = 0
  }
}
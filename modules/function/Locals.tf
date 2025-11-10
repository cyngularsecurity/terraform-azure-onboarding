
locals {

  mgmt_group_id = var.mgmt_group_id
  func_name     = "cyngular-func-${var.client_name}-${var.suffix}"

  func_sp_sku_name        = contains(var.app_insights_unsupported_locations, var.main_location) ? "B2" : "FC1"
  blobStorageAndContainer = "${azurerm_storage_account.func_storage_account.primary_blob_endpoint}deploymentpackage"

  func_zip_url = "https://cyngular-onboarding-templates.s3.us-east-1.amazonaws.com/azure/cyngular_func.zip"

  zip_file_path = "${path.root}/cyngular_func.zip"

  func_env_vars = {
    # "FUNCTIONS_WORKER_RUNTIME" = "python"

    "AzureWebJobsDisableHomepage" = true

    "ENABLE_ORYX_BUILD"              = true
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = true

    "STORAGE_ACCOUNT_MAP"   = jsonencode(var.default_storage_accounts)
    "COMPANY_LOCATIONS"     = jsonencode(var.client_locations)
    "COMPANY_MAIN_LOCATION" = var.main_location

    "COMPANY_NAME" = var.client_name
    "UAI_ID"       = azurerm_user_assigned_identity.function_assignment_identity.client_id

    ENABLE_ACTIVITY_LOGS     = var.enable_activity_logs
    ENABLE_AUDIT_EVENTS_LOGS = var.enable_audit_events_logs
    ENABLE_FLOW_LOGS         = var.enable_flow_logs
    ENABLE_AKS_LOGS          = var.enable_aks_logs

    CACHING_ENABLED = var.caching_enabled
    FAKE_SUBS_N     = 0 // stresser - subscription multiplier
  }
}
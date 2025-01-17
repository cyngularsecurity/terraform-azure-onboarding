
locals {
  mgmt_group_id = data.azuread_client_config.current.tenant_id
  app_insights_unsupported_locations = ["israelcentral"] // ["other"]

  func_name = "cyngular-app-${var.client_name}-${var.suffix}"
  # func_sp_sku_name = var.main_location == "israelcentral" ? "B1" : "Y1"
  func_sp_sku_name = contains(local.app_insights_unsupported_locations, var.main_location) ? "B2" : "Y1"

  func_zip_url  = "https://cyngular-onboarding-templates.s3.us-east-1.amazonaws.com/azure/cyngular_func.zip"
  zip_file_path = "${path.root}/cyngular_func.zip"
}
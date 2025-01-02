
locals {
  func_name = "cyngular-app-${var.client_name}-${var.suffix}"

  mgmt_group_id = data.azuread_client_config.current.tenant_id

  func_sp_sku_name = var.main_location == "israelcentral" ? "B1" : "Y1"

  # func_zip_url  = "https://eastussitesaprod.blob.core.windows.net/cyngular-ob/release/v3.0/Main/function.zip"
  func_zip_url  = "https://cyngular-onboarding-templates.s3.us-east-1.amazonaws.com/azure/cyngular_func.zip"

  zip_file_path = "${path.root}/cyngular_func.zip"

  # blobStorageAndContainer = "${azurerm_storage_account.func_storage_account.primary_blob_endpoint}deploymentpackage"

  app_insights_unsupported_locations = ["israelcentral"] // ["other"]
}
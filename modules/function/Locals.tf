
locals {
  func_name = "cyngular-app-${var.client_name}-${random_string.suffix.result}"

  # func_sku_name = "F1" // free -- do not support function apps -- free
  func_sku_name = "B1" // basic // deployed -- 14.454 USD
  # func_sku_name = "P1v2" // premium // deployed -- 92.345 USD
  # func_sku_name = "Y1" // consumption
  # func_sku_name = "FC1" // flex consumption

  workspace_sku_name = "PerGB2018"

  func_zip_url  = "https://eastussitesaprod.blob.core.windows.net/cyngular-ob/release/v3.0/Main/function.zip"
  zip_file_path = "${path.root}/cyngular_func.zip"

  mgmt_group_id = data.azuread_client_config.current.tenant_id

  # app_insights_unsupported_locations = ["other"]
  app_insights_unsupported_locations = ["israelcentral"]

  func_absolute_location = var.override_location != "" ? var.override_location : var.main_location

  blobStorageAndContainer = "${azurerm_storage_account.func_storage_account.primary_blob_endpoint}deploymentpackage"
}
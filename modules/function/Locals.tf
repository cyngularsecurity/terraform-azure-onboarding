
locals {
  func_name = "cyngular-app-${var.client_name}-${random_string.suffix.result}"

  func_absolute_location = var.override_location != "" ? var.override_location : var.main_location

  func_zip_url  = "https://eastussitesaprod.blob.core.windows.net/cyngular-ob/release/v3.0/Main/function.zip"
  zip_file_path = "${path.root}/cyngular_func.zip"

  mgmt_group_id = data.azuread_client_config.current.tenant_id

  app_insights_unsupported_locations = ["israelcentral"]

  blobStorageAndContainer = "${azurerm_storage_account.func_storage_account.primary_blob_endpoint}deploymentpackage"
}
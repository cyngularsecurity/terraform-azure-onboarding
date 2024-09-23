
locals {
  # func_name = "cyngular-app-${var.client_name}"
  func_name = "cyngular-app-${var.client_name}-${random_string.suffix.result}"

  func_zip_url  = "https://eastussitesaprod.blob.core.windows.net/cyngular-ob/release/v3.0/Main/function.zip"
  zip_file_path = "${path.root}/cyngular_func.zip"

  mgmt_group_id = data.azuread_client_config.current.tenant_id
}

resource "random_string" "suffix" {
  length  = 5
  numeric = true
  special = false
  upper   = false
}

# resource "azurerm_storage_blob" "function_app_zip" {
#   name                   = "function_${random_string.suffix.result}.zip"
#   storage_account_name   = azurerm_storage_account.func_storage_account.name
#   storage_container_name = "function-releases"
#   type                   = "Block"
#   source                 = local.zip_file_path
# }

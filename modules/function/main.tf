
locals {
  func_name = "cyngular-app-${var.client_name}"
  func_zip_url = "https://eastussitesaprod.blob.core.windows.net/cyngular-ob/release/v3.0/Main/function.zip"
  zip_file_path = "${path.root}/cyngular_func.zip"
  
  mgmt_group_id   = data.azuread_client_config.current.tenant_id
}
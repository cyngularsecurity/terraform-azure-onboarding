
data "azuread_client_config" "current" {}

data "archive_file" "function_app_zip" {
  type        = "zip"
  # source_dir  = "${path.module}/function_app"
  source_dir  = "function_app"
  output_path = "cyngular_func.zip"
}
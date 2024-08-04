
data "azuread_client_config" "current" {}

data "archive_file" "function_app_zip" {
  type        = "zip"
  # source_dir  = "${path.module}/function_app"
  source_dir  = "${path.root}/function_app"
  output_path = "${path.root}/cyngular_func.zip"
}

# data "http" "function_zip" {
#   url = "https://github.com/cyngularsecurity/terraform-azure-onboarding/blob/v3.4/cyngular_func.zip"
# }
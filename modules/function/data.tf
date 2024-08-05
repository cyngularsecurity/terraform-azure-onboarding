
data "azuread_client_config" "current" {}

# data "archive_file" "function_app_zip" {
#   type        = "zip"
#   # source_dir  = "${path.module}/function_app"
#   source_dir  = "${path.root}/function_app"
#   output_path = "${path.root}/cyngular_func.zip"
# }

# data "http" "function_zip" {
#   url = "https://github.com/cyngularsecurity/terraform-azure-onboarding/blob/v3.4/cyngular_func.zip"
# }

resource "null_resource" "fetch_zip" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      curl -o ${local.zip_file_path} -L --fail --retry 2 --retry-delay 4 "${local.func_zip_url}"
    EOT
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

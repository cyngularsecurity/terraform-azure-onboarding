
data "azuread_client_config" "current" {}

# data "http" "function_zip" {
#   url = "https://github.com/cyngularsecurity/terraform-azure-onboarding/blob/v3.4/cyngular_func.zip"
# }

data "local_file" "restart_func" {
  filename = "${path.root}/RunBooks/RestartFunc.sh"
}


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

resource "null_resource" "sync_triggers" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<-EOT
      az functionapp restart -n ${local.func_name} -g ${var.cyngular_rg_name}

      rm ${local.zip_file_path}
    EOT
  }
  depends_on = [azurerm_linux_function_app.function_service]
}
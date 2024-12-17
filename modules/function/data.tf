
data "azuread_client_config" "current" {}

# resource "null_resource" "get_zip" {
#   provisioner "local-exec" {
#     interpreter = var.os == "linux" ? ["bash", "-c"] : ["cmd.exe"]
#     command     = <<-EOT
#       set -eu
#       curl -o ${local.zip_file_path} -L --fail --retry 2 --retry-delay 4 "${local.func_zip_url}"
#     EOT
#   }
#   # triggers = { always_run = timestamp() }
# }

# resource "null_resource" "sync_triggers" {
#   provisioner "local-exec" {
#     interpreter = var.os == "linux" ? ["bash", "-c"] : ["cmd.exe"]
#     command     = <<-EOT
#       az functionapp restart -n ${local.func_name} -g ${var.cyngular_rg_name}

#       rm ${local.zip_file_path}
#     EOT
#   }
#   depends_on = [azurerm_linux_function_app.function_service]
#   triggers = {
#     func = azurerm_linux_function_app.function_service.possible_outbound_ip_addresses
#   }
# }

data "http" "zip_file" {
  url = local.func_zip_url
  
  request_headers = {
    Accept = "application/zip"
  }
}

resource "local_file" "zip_file" {
  content_base64 = data.http.zip_file.response_body_base64
  # content  = data.http.zip_file.response_body
  filename = local.zip_file_path
}

# data "http" "zip_file" {
#   url = local.func_zip_url

#   request_headers = {
#     Accept = "application/json"
#   }

#   lifecycle {
#     postcondition {
#       condition     = contains([200], self.status_code)
#       error_message = "Status code invalid"
#     }
#   }
# }
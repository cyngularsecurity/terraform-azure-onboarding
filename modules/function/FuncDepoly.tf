
# resource "terraform_data" "deploy_function_code" {
#   provisioner "local-exec" {
#     interpreter = ["bash", "-c"]
#     command     = local.deploy_script_path

#     environment = local.deploy_script_env
#   }

#   # provisioner "local-exec" {
#   #   command     = "sleep 20"
#   # }

#   # provisioner "local-exec" {
#   #   command     = local.sync_triggers_command
#   #   # on_failure = continue
#   # }

#   # triggers_replace = [
#   #   timestamp()
#   # ]

#   depends_on = [
#     azurerm_linux_function_app.function_service
#   ]
# }

# resource "terraform_data" "get_zip" {
#   provisioner "local-exec" {
#     interpreter = var.os == "linux" ? ["bash", "-c"] : ["cmd.exe"]
#     command     = <<-EOT
#       curl -o ${local.zip_file_path} -L --fail --retry 2 --retry-delay 4 "${local.func_zip_url}"
#     EOT
#   }
#   # triggers = {
#   #   always_run = timestamp()
#   # }
# }

# resource "terraform_data" "sync_triggers" {
#   provisioner "local-exec" {
#     interpreter = var.os == "linux" ? ["bash", "-c"] : ["cmd.exe"]
#     command = <<-EOT
#       az functionapp restart -n ${local.func_name} -g ${var.cyngular_rg_name}

#       rm ${local.zip_file_path}
#     EOT
#   }
  
#   triggers_replace = {
#     func = azurerm_linux_function_app.function_service.possible_outbound_ip_addresses
#     # always_run = timestamp()
#   }

#   depends_on = [azurerm_linux_function_app.function_service]
# }
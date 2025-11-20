resource "terraform_data" "deploy_function_cli" {
  count = var.use_cli_deployment ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "Downloading function code from ${local.func_zip_url}"
      curl -sL -f -o ${local.zip_file_path} ${local.func_zip_url} || exit 1
      echo "Download completed successfully"
    EOT
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo -e "Deploying to function ${local.func_name}"
      az functionapp deployment source config-zip \
        --resource-group ${var.cyngular_rg_name} \
        --name ${local.func_name} \
        --src ${local.zip_file_path}
    EOT
  }

  triggers_replace = {
    function_name = azurerm_function_app_flex_consumption.function_service.name
  }

  depends_on = [
    azurerm_function_app_flex_consumption.function_service,
  ]
}

resource "terraform_data" "deploy_function_cli_unix" {
  count = var.use_cli_deployment && !local.is_windows ? 1 : 0


  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -e
      echo "Downloading function code from ${local.func_zip_url}"
      curl -sL -f -o ${local.zip_file_path} ${local.func_zip_url}
      echo "Download completed successfully"
    EOT
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -e
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

resource "terraform_data" "deploy_function_cli_windows" {
  count = var.use_cli_deployment && local.is_windows ? 1 : 0

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = <<-EOT
      $ErrorActionPreference = "Stop"
      Write-Output "Downloading function code from ${local.func_zip_url}"
      $ProgressPreference = 'SilentlyContinue'
      Invoke-WebRequest -Uri "${local.func_zip_url}" -OutFile "${local.zip_file_path}"
      if (-not (Test-Path "${local.zip_file_path}")) { 
        Write-Error "File not found after download"
        exit 1 
      }
      Write-Output "Download completed successfully"
    EOT
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = <<-EOT
      $ErrorActionPreference = "Stop"
      Write-Output "Deploying to function ${local.func_name}"
      az functionapp deployment source config-zip `
        --resource-group ${var.cyngular_rg_name} `
        --name ${local.func_name} `
        --src ${local.zip_file_path}
      
      if ($LASTEXITCODE -ne 0) {
        Write-Error "Deployment failed with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
      }
    EOT
  }

  triggers_replace = {
    function_name = azurerm_function_app_flex_consumption.function_service.name
  }

  depends_on = [
    azurerm_function_app_flex_consumption.function_service,
  ]
}

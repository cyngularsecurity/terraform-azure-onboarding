resource "azurerm_storage_account" "func_storage_account" {
  # name                = lower(substr("cyngularsa${each.key}", 0, 24))
  name                = "cyngularapp${var.client_name}"
  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  access_tier               = "Hot"
  enable_https_traffic_only = true

  tags = var.tags
}

resource "azurerm_application_insights" "func_azure_insights" {
  name                = "cyngular-service-${var.client_name}"
  resource_group_name = var.cyngular_rg_name
  location            = var.main_location
  application_type    = "web"
  retention_in_days   = 60
  tags                = var.tags
}

resource "azurerm_service_plan" "regular" {
  name                = "ASP-cyngular-service-regular"
  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  os_type  = "Linux"
  sku_name = "Y1"
  tags     = var.tags
}

data "azurerm_function_app_host_keys" "function_service" {
  name                = local.func_name
  resource_group_name = var.cyngular_rg_name
  depends_on          = [azurerm_linux_function_app.function_service]
}

resource "null_resource" "deploy" {
  provisioner "local-exec" {
    command     = <<-EOT

      az functionapp deployment source config-zip \
        -g "${RESOURCE_GROUP}" -n "${FUNCTION_APP_NAME}" \
        --src "https://devsitesawestus2.blob.core.windows.net/cyngular-client-function/cyngular_func.zip?se=2024-08-02T00%3A03Z&sp=r&spr=https&sv=2022-11-02&sr=b&sig=T4cMcbc4Hc1fsLPRC9L1XaaZLW%2F6EgCYzZup%2BeK1TUg%3D"

      # curl -X POST "https://${var.function_app_name}.azurewebsites.net/admin/host/synctriggers?code=$(terraform output -raw default_host_key)" -H "Content-Length: 0"    
    EOT
    environment = {
      RESOURCE_GROUP       = var.cyngular_rg_name
      FUNCTION_APP_NAME         = local.func_name
    }
  }
}

# resource "null_resource" "sync_triggers" {
#   provisioner "local-exec" {
#     interpreter = ["bash", "-c"]
#     command = <<-EOT
#       az functionapp restart -n ${local.func_name} -g ${var.cyngular_rg_name}
#       URL="https://${azurerm_linux_function_app.function_service.default_hostname}/admin/host/synctriggers?code=${data.azurerm_function_app_host_keys.function_service.default_function_key}"
#       # URL="https://management.azure.com${azurerm_linux_function_app.function_service.id}/syncfunctiontriggers?api-version=2016-08-01"
#       echo $URL | tee > url.txt
#       curl -X POST $URL -H "Content-Length: 0"
#     EOT
#   }
#   # depends_on = [data.azurerm_function_app_host_keys.function_service]
# }

# output "default_host_key" {
#   value = data.azurerm_function_app_host_keys.function_service.default_function_key
# }
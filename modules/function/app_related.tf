resource "azurerm_storage_account" "func_storage_account" {
  name                = lower(substr("${var.client_name}csafunc", 0, 24))
  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  access_tier               = "Hot"
  https_traffic_only_enabled  = true
  tags = var.tags
}

resource "azurerm_application_insights" "func_azure_insights" {
  name                = "cyngular-service-${var.client_name}"
  resource_group_name = var.cyngular_rg_name
  location            = var.main_location
  application_type    = "other"
  retention_in_days   = 60
  tags                = var.tags
}

resource "azurerm_service_plan" "regular" {
  name                = "ASP-cyngular-service-regular"
  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  os_type  = "Linux"
  sku_name = "Y1" // EP2 // Y1
  tags     = var.tags
}

# resource "azurerm_app_service_source_control" "function_service" {
#   app_id                 = azurerm_linux_function_app.function_service.id
#   repo_url               = "https://github.com/Azure-Samples/flask-app-on-azure-functions.git"
#   branch                 = "main"
#   use_manual_integration = true
# }

# data "azurerm_function_app_host_keys" "function_service" {
#   name                = local.func_name
#   resource_group_name = var.cyngular_rg_name
#   depends_on          = [azurerm_linux_function_app.function_service]
# }

# resource "null_resource" "deploy" {
#   provisioner "local-exec" {
#     command     = <<-EOT

#       az functionapp deployment source config-zip \
#         -g "${var.cyngular_rg_name}" -n "${local.func_name}" \
#         --src "https://devsitesawestus2.blob.core.windows.net/cyngular-client-function/cyngular_func.zip?se=2024-08-02T00%3A03Z&sp=r&spr=https&sv=2022-11-02&sr=b&sig=T4cMcbc4Hc1fsLPRC9L1XaaZLW%2F6EgCYzZup%2BeK1TUg%3D"
#     EOT
#   }
# }
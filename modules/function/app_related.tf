resource "azurerm_storage_account" "func_storage_account" {
  name = lower(substr("cyngularapp${var.suffix}", 0, 23))

  resource_group_name = var.cyngular_rg_name
  location            = local.func_absolute_location

  cross_tenant_replication_enabled = false
  account_kind                     = "StorageV2"
  account_tier                     = "Standard"
  account_replication_type         = "LRS"
  min_tls_version                  = "TLS1_2"

  access_tier                = "Hot"
  https_traffic_only_enabled = true
  tags                       = var.tags
}

resource "azurerm_application_insights" "func_azure_insights" {
  count               = contains(local.app_insights_unsupported_locations, local.func_absolute_location) ? 0 : 1

  name                = "cyngular-service-${var.client_name}"
  resource_group_name = var.cyngular_rg_name
  location            = local.func_absolute_location

  # application_type  = "other"
  application_type    = "web"
  # workspace_id = azurerm_log_analytics_workspace.logAnalyticsWorkspace.id

  retention_in_days = 60
  tags              = var.tags
}

# resource "azurerm_storage_container" "func_storage_container" {
#   name                  = "deploymentpackage"
#   storage_account_name  = azurerm_storage_account.func_storage_account.name
#   container_access_type = "private"
# }

# resource "azurerm_log_analytics_workspace" "logAnalyticsWorkspace" {
#   name                = "cyngular-service-${var.client_name}"
#   resource_group_name = var.cyngular_rg_name
#   location            = local.func_absolute_location
#   sku                 = "PerGB2018"
#   retention_in_days   = 30
# }

resource "azurerm_service_plan" "regular" {
  name                = "ASP-cyngular-service-regular"
  resource_group_name = var.cyngular_rg_name
  location            = local.func_absolute_location

  os_type  = "Linux"
  # sku_name = contains(local.app_insights_unsupported_locations, lower(local.func_absolute_location)) ? "B1" : "Y1"

  sku_name = "Y1" // "FC1"
  tags     = var.tags
}
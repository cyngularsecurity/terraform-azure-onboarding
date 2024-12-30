
resource "azurerm_service_plan" "main" {
  name                = "ASP-cyngular-service-${local.func_sp_sku_name}"

  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  os_type  = "Linux"
  sku_name = local.func_sp_sku_name

  tags     = var.tags
}

resource "azurerm_storage_account" "func_storage_account" {
  name = lower(substr("cyngularapp${var.suffix}", 0, 23))

  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  cross_tenant_replication_enabled = false
  account_kind                     = "StorageV2"
  account_tier                     = "Standard"
  account_replication_type         = "LRS"
  min_tls_version                  = "TLS1_2"

  access_tier                = "Hot"
  https_traffic_only_enabled = true
  shared_access_key_enabled = false

  tags                       = var.tags
}

resource "azurerm_application_insights" "func_azure_insights" {
  count               = contains(local.app_insights_unsupported_locations, var.main_location) ? 0 : 1

  name                = "cyngular-service-${var.client_name}"
  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  application_type    = "web" // "other"

  retention_in_days = 60
  tags              = var.tags
}
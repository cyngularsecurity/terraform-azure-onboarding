resource "azurerm_storage_account" "func_storage_account" {
  name = lower(substr("cyngularapp${var.suffix}", 0, 23))

  resource_group_name = var.cyngular_rg_name
  location            = var.override_location != "" ? var.override_location : var.main_location

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
  name                = "cyngular-service-${var.client_name}"
  resource_group_name = var.cyngular_rg_name
  location            = var.override_location != "" ? var.override_location : var.main_location

  application_type  = "other"
  retention_in_days = 60
  tags              = var.tags
}

resource "azurerm_service_plan" "regular" {
  name                = "ASP-cyngular-service-regular"
  resource_group_name = var.cyngular_rg_name
  location            = var.override_location != "" ? var.override_location : var.main_location

  os_type  = "Linux"
  sku_name = "Y1"
  tags     = var.tags
}
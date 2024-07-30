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
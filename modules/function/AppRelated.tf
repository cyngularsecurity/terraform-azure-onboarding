
resource "azurerm_service_plan" "main" {
  name                = "ASP-cyngular-service-${local.func_sp_sku_name}"

  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  os_type  = "Linux"
  sku_name = local.func_sp_sku_name

  tags = merge(var.tags, {
    "ServicePlanSKU": local.func_sp_sku_name
    "RelatedFuncName": local.func_name
  })
}

resource "azurerm_storage_account" "func_storage_account" {
  name = lower(substr("cyngularapp${var.suffix}", 0, 23))

  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = merge(var.tags, {
    "RelatedFuncName": local.func_name
  })
}

resource "azurerm_application_insights" "func_azure_insights" {
  count               = contains(var.app_insights_unsupported_locations, var.main_location) ? 0 : 1

  name                = "cyngular-service-${var.client_name}"
  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  application_type    = "web"
  retention_in_days = 60

  tags = merge(var.tags, {
    "RelatedFuncName": local.func_name
  })
}

resource "azurerm_service_plan" "main" {
  name = "ASP-cyngular-func-${local.func_sp_sku_name}"

  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  os_type  = "Linux"
  sku_name = local.func_sp_sku_name

  tags = merge(var.tags, {
    "ServicePlanSKU" : local.func_sp_sku_name
    "RelatedFuncName" : local.func_name
  })
}

resource "azurerm_storage_account" "func_storage_account" {
  name = lower(substr("cyngularfunc${var.client_name}", 0, 23))

  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = merge(var.tags, {
    "RelatedFuncName" : local.func_name
  })
}

resource "azurerm_storage_container" "storageContainer" {
  name                  = "deploymentpackage"
  storage_account_id    = azurerm_storage_account.func_storage_account.id
  container_access_type = "private"
}

resource "azurerm_log_analytics_workspace" "func_log_analytics" {
  name  = "cyngular-func-workspace-${var.client_name}"
  count = var.allow_function_logging ? 1 : 0

  location            = var.main_location
  resource_group_name = var.cyngular_rg_name

  sku               = "PerGB2018"
  retention_in_days = 30

  tags = merge(var.tags, {
    "RelatedFuncName" : local.func_name
  })
}

resource "azurerm_application_insights" "func_azure_insights" {
  name  = "cyngular-func-insights-${var.client_name}"
  count = var.allow_function_logging ? 1 : 0

  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  application_type  = "other"
  retention_in_days = 60
  workspace_id      = azurerm_log_analytics_workspace.func_log_analytics[count.index].id

  tags = merge(var.tags, {
    "RelatedFuncName" : local.func_name
  })
}
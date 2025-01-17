
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

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags                       = var.tags
}

resource "azurerm_application_insights" "func_azure_insights" {
  count               = contains(local.app_insights_unsupported_locations, var.main_location) ? 0 : 1

  name                = "cyngular-service-${var.client_name}"
  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  application_type    = "web"
  retention_in_days = 60

  # # workspace_id = contains(local.app_insights_unsupported_locations, local.func_absolute_location) ? null : azurerm_log_analytics_workspace.func_azure_log_analytics_workspace[0].id
  # workspace_id = try(azurerm_log_analytics_workspace.func_azure_log_analytics_workspace[0].id, null)

  tags              = var.tags
}

resource "null_resource" "sync_triggers" {
  provisioner "local-exec" {
    command     = <<-EOT
      az rest --method post \
        --url "https://management.azure.com/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.cyngular_rg_name}/providers/Microsoft.Web/sites/${local.func_name}/syncfunctiontriggers?api-version=2016-08-01"

    EOT
    on_failure = continue
  }

  depends_on = [azurerm_linux_function_app.function_service]
}
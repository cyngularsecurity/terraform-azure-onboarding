
resource "azurerm_service_plan" "main" {
  name                = "ASP-cyngular-service-${local.func_sku_name}"
  resource_group_name = var.cyngular_rg_name
  location            = local.func_absolute_location

  os_type  = "Linux"
  sku_name = local.func_sku_name

  tags     = var.tags
}

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
  # shared_access_key_enabled = false

  tags                       = var.tags
}

resource "azurerm_log_analytics_workspace" "func_azure_log_analytics_workspace" {
  count               = contains(local.app_insights_unsupported_locations, local.func_absolute_location) ? 1 : 0

  name                = "cyngular-workspace-${var.client_name}"
  location            = local.func_absolute_location
  resource_group_name = var.cyngular_rg_name

  sku                 = local.workspace_sku_name
  retention_in_days   = 30
}

resource "azurerm_application_insights" "func_azure_insights" {
  name                = "cyngular-service-${var.client_name}"
  resource_group_name = var.cyngular_rg_name
  location            = local.func_absolute_location

  # application_type  = "other"
  application_type    = "web"
  # workspace_id = contains(local.app_insights_unsupported_locations, local.func_absolute_location) ? null : azurerm_log_analytics_workspace.func_azure_log_analytics_workspace[0].id
  workspace_id = try(azurerm_log_analytics_workspace.func_azure_log_analytics_workspace[0].id, null)

  retention_in_days = 60
  tags              = var.tags
}

resource "azurerm_storage_container" "func_storage_container" {
  name                  = "deploymentpackage"
  storage_account_id    = azurerm_storage_account.func_storage_account.id
  container_access_type = "private"
}

resource "azurerm_storage_blob" "zip_deployment" {

  name                   = "function.zip"
  storage_account_name   = azurerm_storage_account.func_storage_account.name
  storage_container_name = azurerm_storage_container.func_storage_container.name

  type                   = "Block"
  source                 = local.zip_file_path

}

resource "null_resource" "sync_triggers" {
  provisioner "local-exec" {
    command = <<EOT
      az rest --method post \
        --url "https://management.azure.com/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.cyngular_rg_name}/providers/Microsoft.Web/sites/${local.func_name}/syncfunctiontriggers?api-version=2016-08-01"
    EOT
    on_failure = continue
  }

  depends_on = [azurerm_linux_function_app.function_service]
}

output "sync_triggers" {
  value = try(jsondecode(nonsensitive(null_resource.sync_triggers.triggers.stderror)), null)
}
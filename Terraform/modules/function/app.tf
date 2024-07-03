
resource "azurerm_linux_function_app" "function_service" {
  name                = "cyngular-service-${var.client_name}"
  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  https_only                    = true
  public_network_access_enabled = true

  service_plan_id           = azurerm_service_plan.regular.id
  storage_account_name       = azurerm_storage_account.func_storage_account.name
  storage_account_access_key = azurerm_storage_account.func_storage_account.primary_access_key

  app_settings = {
      # "SCM_DO_BUILD_DURING_DEPLOYMENT" = true,
    "FUNCTIONS_WORKER_RUNTIME"       = "python",
    "FUNCTIONS_EXTENSION_VERSION" = "~4",

    "STORAGE_ACCOUNT_MAPPINGS"       = jsonencode(var.default_storage_accounts),
    "COMPANY_LOCATIONS" = jsonencode(var.client_locations),
    "ROOT_MGMT_GROUP_ID" = local.mgmt_group_id,
    "UAI_ID"       = azurerm_user_assigned_identity.function_assignment_identity.client_id,

    "enable_activity_logs"     = var.enable_activity_logs
    "enable_audit_events_logs" = var.enable_audit_events_logs
    "enable_flow_logs"         = var.enable_flow_logs
    "enable_aks_logs"          = var.enable_aks_logs

  }

  site_config {
    application_insights_connection_string = azurerm_application_insights.func_azure_insights.connection_string
    application_insights_key               = azurerm_application_insights.func_azure_insights.instrumentation_key
    application_stack {
      python_version = "3.11"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function_assignment_identity.id]
  }

  # lifecycle {
  #   ignore_changes = [
  #     app_settings
  #   ]
  # }
  zip_deploy_file = var.service_zip
  tags = var.tags
}

resource "azurerm_storage_account" "func_storage_account" {
  name                = "cyngularservice${var.client_name}"
  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version = "TLS1_2"

  access_tier              = "Hot"
  enable_https_traffic_only = true

  tags = var.tags
}

resource "azurerm_application_insights" "func_azure_insights" {
  name                = "cyngular-service-${var.client_name}"
  resource_group_name = var.cyngular_rg_name
  location            = var.main_location
  application_type    = "web"
  retention_in_days   = 60
  tags       = var.tags
}

resource "azurerm_service_plan" "regular" {
  name                = "ASP-cyngular-service-regular"
  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  os_type  = "Linux"
  sku_name = "Y1"
  tags = var.tags
}
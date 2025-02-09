
resource "azurerm_linux_function_app" "function_service" {
  name                = local.func_name
  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  https_only                    = true

  service_plan_id            = azurerm_service_plan.main.id
  storage_account_name       = azurerm_storage_account.func_storage_account.name
  storage_account_access_key = azurerm_storage_account.func_storage_account.primary_access_key

  zip_deploy_file = local.zip_file_path

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function_assignment_identity.id]
  }

  app_settings = local.func_env_vars

  site_config {
    application_insights_connection_string = try(azurerm_application_insights.func_azure_insights[0].connection_string, null)
    application_insights_key               = try(azurerm_application_insights.func_azure_insights[0].instrumentation_key, null)

    application_stack {
      python_version = "3.12"
    }

    # app_service_logs {
    #   disk_quota_mb         = 100
    #   retention_period_days = 3
    # }
  }

  tags = var.tags

  depends_on = [
    local_sensitive_file.zip_file,
    azurerm_role_assignment.func_assigment_custom_mgmt,
    azurerm_role_assignment.func_assigment_reader_mgmt,
    azurerm_role_assignment.sa_contributor,
    azurerm_role_assignment.blob_contributor
  ]
}
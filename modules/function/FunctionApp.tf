resource "azurerm_linux_function_app" "function_service" {
  name                = local.func_name
  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  https_only = true

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

    ip_restriction {
      name       = "allow-creator-ip"
      action     = "Allow"
      priority   = 100
      ip_address = "${var.creator_local_ip}/32"
    }

    scm_use_main_ip_restriction = true
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags["hidden-link: /app-insights-resource-id"]
    ]
  }

  # key_vault...

  depends_on = [
    local_sensitive_file.zip_file,
    azurerm_role_assignment.func_assigment_custom_mgmt,
    azurerm_role_assignment.func_assigment_reader_mgmt,
    azurerm_role_assignment.cyngular_sa_contributor,
    azurerm_role_assignment.cyngular_blob_owner,
    azurerm_role_assignment.cyngular_main_storage_table_contributor
  ]
}
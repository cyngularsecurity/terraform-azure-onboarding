resource "azurerm_function_app_flex_consumption" "function_service" {
  name                = local.func_name
  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  service_plan_id = azurerm_service_plan.main.id

  storage_container_type      = "blobContainer"
  storage_container_endpoint  = local.blobStorageAndContainer
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.func_storage_account.primary_access_key

  runtime_name    = "python"
  runtime_version = "3.12"

  app_settings = local.func_env_vars

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function_assignment_identity.id]
  }

  site_config {
    application_insights_connection_string = try(azurerm_application_insights.func_azure_insights[0].connection_string, null)
    application_insights_key               = try(azurerm_application_insights.func_azure_insights[0].instrumentation_key, null)

    ip_restriction {
      name       = "allow-creator-ip"
      action     = "Allow"
      priority   = 100
      ip_address = "${var.creator_local_ip}/32"
    }

    scm_use_main_ip_restriction = true
  }

  tags = var.tags

  depends_on = [
    # local_sensitive_file.zip_file,
    azurerm_role_assignment.func_assigment_custom_mgmt,
    azurerm_role_assignment.func_assigment_reader_mgmt,
    azurerm_role_assignment.cyngular_sa_contributor,
    azurerm_role_assignment.cyngular_blob_owner,
    azurerm_role_assignment.cyngular_main_storage_table_contributor
  ]
}
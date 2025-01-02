
resource "azurerm_linux_function_app" "function_service" {
  name                = local.func_name
  resource_group_name = var.cyngular_rg_name
  location            = var.main_location

  # https_only                    = true
  # public_network_access_enabled = true

  service_plan_id            = azurerm_service_plan.main.id
  storage_account_name       = azurerm_storage_account.func_storage_account.name
  storage_account_access_key = azurerm_storage_account.func_storage_account.primary_access_key

  zip_deploy_file = local.zip_file_path

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function_assignment_identity.id]
  }

  app_settings = {
    # "FUNCTIONS_WORKER_RUNTIME"    = "python"
    # "AzureWebJobsDisableHomepage" = true

    # "AzureWebJobsStorage__accountName" = azurerm_storage_account.func_storage_account.name
    # "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.func_storage_account.name};AccountKey=${azurerm_storage_account.func_storage_account.primary_access_key};EndpointSuffix=${azurerm_storage_account.func_storage_account.primary_blob_endpoint}"
    # "WEBSITE_CONTENTSHARE" = lower(local.func_name)

    # "WEBSITE_RUN_FROM_PACKAGE" = "https://${azurerm_storage_account.func_storage_account.name}.blob.core.windows.net/${resource.azurerm_storage_container.func_storage_container.name}/${resource.azurerm_storage_blob.zip_deployment.name}"
    # "WEBSITE_RUN_FROM_PACKAGE" = 1

    "ENABLE_ORYX_BUILD"              = true
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = true

    "STORAGE_ACCOUNT_MAPPINGS" = jsonencode(var.default_storage_accounts)
    "COMPANY_LOCATIONS"        = jsonencode(var.client_locations)

    "ROOT_MGMT_GROUP_ID"       = local.mgmt_group_id
    "UAI_ID"                   = azurerm_user_assigned_identity.function_assignment_identity.client_id
    "enable_activity_logs"     = var.enable_activity_logs
    "enable_audit_events_logs" = var.enable_audit_events_logs
    "enable_flow_logs"         = var.enable_flow_logs
    "enable_aks_logs"          = var.enable_aks_logs
  }

  site_config {
      # always_on = azurerm_service_plan.main.sku_name != "F1" || azurerm_service_plan.main.sku_name != "Y1"
      # app_scale_limit = azurerm_service_plan.main.sku_name != "F1" ? 1 : 0

    application_insights_connection_string = try(azurerm_application_insights.func_azure_insights[0].connection_string, null)
    application_insights_key               = try(azurerm_application_insights.func_azure_insights[0].instrumentation_key, null)

    application_stack {
      # python_version = "3.11"
      python_version = "3.12"
    }
    # app_command_line = <<-EOF
    #   #!/bin/bash
    #   echo "${local.function_app_zip_content}" | base64 --decode > /home/site/wwwroot/function_app.zip
    #   unzip /home/site/wwwroot/function_app.zip -d /home/site/wwwroot
    # EOF
  }
  
  tags = var.tags
  # lifecycle {
  #   ignore_changes = [
  #     # app_settings,
  #     tags
  #   ]
  # }
  depends_on = [
    local_file.zip_file
  ]
}
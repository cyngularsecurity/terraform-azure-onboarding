
# locals {
#   base_app_settings = {
#     "SCM_DO_BUILD_DURING_DEPLOYMENT" = true
#     "AZURE_SECRET_NAME" = var.kv_name
#     "FUNCTIONS_WORKER_RUNTIME"       = "python"
#     "SUBSCRIPTION_ID" = var.subscription_id
#     "FUNCTIONS_EXTENSION_VERSION" = "~4"
#   }
# }

# resource "azurerm_linux_function_app" "function_service" {

#   name                = "${replace(var.func_name,"_","-")}-service-${var.client_name}"
#   resource_group_name = var.client_rg.name
#   location            = var.client_rg.location

#   https_only                    = true
#   public_network_access_enabled = false

#   virtual_network_subnet_id = var.func_name == "os_service3" ? var.os_subnet_id : null
  
#   service_plan_id           = var.service_plan_id
#   storage_account_name       = azurerm_storage_account.func_storage_account.name
#   storage_account_access_key = azurerm_storage_account.func_storage_account.primary_access_key

#   app_settings = merge(
#     local.base_app_settings,
#     var.func_name == "os_service1" ? { "FIRST_RUN" = 1 } : {},
#     var.func_name == "os_service2" ? { "AzureWebJobsServiceBus" = var.linux_service_bus_ns_conn_str } : {},
#     var.func_name == "visibility" ? local.visibility_app_settings : {})

#   site_config {
#     application_insights_connection_string = azurerm_application_insights.func_azure_insights.connection_string
#     application_insights_key               = azurerm_application_insights.func_azure_insights.instrumentation_key
#     always_on                              = var.func_name == "os_service2" ? true : null
#     application_stack {
#       python_version = "3.11"
#     }
#   }

#   identity {
#     type = "SystemAssigned"
#   }


#   lifecycle {
#     ignore_changes = [
#       app_settings
#     ]
#   }
#   zip_deploy_file = var.service_zip
#   tags = var.tags
# }

# # ------< storage account of linux function >----------------------------
# resource "azurerm_storage_account" "func_storage_account" {
#   name = format("%ssa", replace(var.func_name,"_",""))
#   resource_group_name      = var.client_rg.name
#   location                 = var.client_rg.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
#   tags = var.tags
# }

# # ------< app insights of linux function >----------------------------
# resource "azurerm_application_insights" "func_azure_insights" {
#   name                = "${var.func_name}-service-${var.client_name}"
#   resource_group_name = var.client_rg.name
#   location            = var.client_rg.location
#   application_type    = "web"
#   retention_in_days   = 60
#   tags       = var.tags
# }

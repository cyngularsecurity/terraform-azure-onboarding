# resource "azapi_resource" "regular_service_plan" {
#   type = "Microsoft.Web/serverfarms@2024-04-01"
#   # schema_validation_enabled = false

#   location = local.func_absolute_location
#   name = "cyngular-service-${var.client_name}"

#   parent_id = var.cyngular_rg_id

#   body = {
#     # properties = {
#     #   reserved = true
#     # }
#     kind = "functionapp"
#     sku = {
#       # tier = "FlexConsumption"
#       # tier = contains(local.app_insights_unsupported_locations, lower(local.func_absolute_location)) ? "FlexConsumption" : "Y1"
#       name = contains(local.app_insights_unsupported_locations, lower(local.func_absolute_location)) ? "B1" : "Y1"
#     }
#   }

#   response_export_values = ["properties"]

#   lifecycle {
#     ignore_changes = [
#       body.properties.encryption.keySource
#     ]
#   }
# }

# resource "azapi_resource" "functionApps" {
#   type = "Microsoft.Web/sites@2024-04-01"
#   # schema_validation_enabled = false

#   name = local.func_name
#   location = local.func_absolute_location

#   parent_id = var.cyngular_rg_id
#   body = {
#     kind = "functionapp,linux"
#     identity = {
#       type: "SystemAssigned"
#     }
#     properties = {
#       serverFarmId = azapi_resource.regular_service_plan.id
#         # functionAppConfig = {
#         #   deployment = {
#         #     storage = {
#         #       type = "blobContainer"
#         #       value = local.blobStorageAndContainer
#         #       authentication = {
#         #         type = "SystemAssignedIdentity"
#         #       }
#         #     }
#         #   },
#         #   scaleAndConcurrency = {
#         #     maximumInstanceCount = 1
#         #     instanceMemoryMB = 1024
#         #   },
#         #   runtime = { 
#         #     name = "python",
#         #     version = "3.12"
#         #   }
#         # },
#         siteConfig = {
#           appSettings = [
#             {
#               name = "AzureWebJobsStorage__accountName"
#               value = azurerm_storage_account.func_storage_account.name
#             },
#             {
#               name = "APPLICATIONINSIGHTS_CONNECTION_STRING"
#               value = try(azurerm_application_insights.func_azure_insights[0].connection_string, null)
#             }
#           ]
#         }
#         functionAppConfig = {
#           deployment = {
#             storage = {
#               type = "blobContainer"
#               value = local.blobStorageAndContainer
#               authentication = {
#               type = "SystemAssignedIdentity"
#             }
#           }
#         }
#       }
#     }
#   }
# }

# # resource "azapi_resource_action" "restart_function" {
# #   type        = "Microsoft.Web/sites@2022-03-01"
# #   resource_id = azurerm_linux_function_app.function_service.id
# #   action      = "restart"
# #   method      = "POST"

# #   depends_on = [azurerm_linux_function_app.function_service]
# # }

# data "azurerm_linux_function_app" "fn_wrapper" {
#     name = local.func_name
#     resource_group_name = var.cyngular_rg_name
# }

# resource "azurerm_role_assignment" "storage_roleassignment" {
#   scope = azurerm_storage_account.func_storage_account.id
#   role_definition_name = "Storage Blob Data Owner"
#   principal_id = data.azurerm_linux_function_app.fn_wrapper.identity.0.principal_id
# }
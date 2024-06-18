
# resource "azurerm_policy_definition" "activity_logs_diagnostic_settings" {
#   name         = "cyngular-activity-logs"
#   policy_type  = "Custom"
#   mode         = "All"
#   display_name = "apply activity logs per subscription"
#   description  = "cyngular diagnostic settings deployment of subscription"

#   metadata = jsonencode({ category = "Monitoring" })

#   parameters = jsonencode({
#     subscription = {
#       type = "String"
#       metadata = {
#         displayName = "Subscription ID"
#         description = "Id of subscription scope the policy will be assigned to"
#       }
#     }
#     location = {
#       type = "String"
#       metadata = {
#         displayName = "location"
#         description = "Location where storage account will be deployed"
#       }
#     }

#     storageAccounts = {
#       type = "Object"
#       metadata = {
#         displayName = "Storage Accounts by Location"
#         description = "A map of locations to lists of storage account IDs."
#       }    }

#     storageAccountID = {
#       type = "String"
#       metadata = {
#         displayName = "Storage Account"
#         description = "storage account ID"
#       }
#     }
#   })

#   policy_rule = jsonencode({
#     if = {
#       field  = "type"
#       equals = "Microsoft.Resources/subscriptions"
#     },
#     then = {
#       effect = "deployIfNotExists"
#       details = {
#         type = "Microsoft.Insights/diagnosticSettings"
#         # "existenceCondition": {
#         #   "allOf": [
#         #     {
#         #       "field": "Microsoft.Insights/diagnosticSettings/logs.enabled",
#         #       "equals": "true"
#         #     },
#         #     {
#         #       "field": "Microsoft.Insights/diagnosticSettings/logs.category",
#         #       "equals": "Administrative"
#         #     }
#         #   ]
#         # },
#         roleDefinitionIds = [
#           "/providers/Microsoft.Authorization/roleDefinitions/StorageAccountContributor",
#           "/providers/Microsoft.Authorization/roleDefinitions/ccca81f6-c8dc-45e2-8833-a5e13f9ae238" // monitoring contributor
#         ]
#         deployment = {
#           properties = {
#             mode = "incremental"
#             parameters = {
#               subscription = {
#                 value = "[parameters('subscription')]"
#               }
#               location = {
#                 value = "[field('location')]"
#               }
#               storageAccountId = {
#                 value = "[parameters('storageAccountID')]"
#               }
#             }
#             template = {
#               "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
#               contentVersion = "1.0.0.0"
#               parameters = {
#                 subscription = {
#                   type = "string"
#                 }
#                 location = {
#                   type = "string"
#                 }
#                 storageAccountId = {
#                   type = "string"
#                 }
#               }
#               resources = [
#                 {
#                   type       = "Microsoft.Insights/diagnosticSettings"
#                   apiVersion = "2017-05-01-preview"
#                   name       = "[concat(parameters('subscription'), '-activity-logs')]"
#                   location   = "[parameters('location')]"
#                   properties = {
#                     # storageAccountId = "[parameters('storageAccountId')]"
#                     storageAccountId = "[parameters('storageAccounts')[field('location')][0]]"
#                     logs = [
#                       {
#                         category = "Recommendation"
#                         enabled  = true
#                         retentionPolicy = {
#                           enabled = false
#                           days    = 30
#                         }
#                       },
#                       {
#                         category = "Alert"
#                         enabled  = true
#                       },
#                       {
#                         category = "ServiceHealth"
#                         enabled  = true
#                       },
#                       {
#                         category = "Administrative"
#                         enabled  = true
#                       },
#                       {
#                         category = "Security"
#                         enabled  = true
#                       },
#                       {
#                         category = "Policy"
#                         enabled  = true
#                       },
#                       {
#                         category = "Autoscale"
#                         enabled  = true
#                       },
#                       {
#                         category = "ResourceHealth"
#                         enabled  = true
#                       }
#                     ]
#                   }
#                 }
#               ]
#             }
#           }
#         }
#       }
#     }
#   })
# }
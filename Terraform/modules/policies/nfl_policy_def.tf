# resource "azurerm_policy_definition" "nsg_flow_logs" {
#   count        = var.enable_flow_logs ? 1 : 0

#   name         = "cyngular-${var.client_name}-nsg-flow-logs-def"
#   policy_type  = "Custom"
#   mode         = "Indexed"
#   display_name = "Cyngular ${var.client_name} NSG Flow Logs - Apply flow logs on nsgs without"
#   description  = "Ensures that NSG Flow Logs are configured to send logs to the specified storage account."

#   metadata = jsonencode({ category = "Monitoring" })
#   parameters = jsonencode({
#     StorageAccountIds = {
#       type = "Object"
#       metadata = {
#         description = "A map of locations to storage account IDs where the logs should be sent."
#         displayName = "Storage Account Map"
#       }
#     }
#     ClientLocations = {
#       type = "Array"
#       metadata = {
#         description = "The list of allowed locations for AKS clusters."
#         displayName = "Allowed Locations"
#       }
#     }
#   })

#   policy_rule = jsonencode({
#     if = {
#       allOf = [
#         {
#           field = "type"
#           equals = "Microsoft.Network/networkSecurityGroups"
#         }
#       ]
#     },
#     then = {
#       anyOf = [
#         {
#           allOf = [
#             {
#               field = "location"
#               in = "[parameters('allowedLocations')]"
#             },
#             {
#               effect = "DeployIfNotExists"
#               details = {
#                 type = "Microsoft.Network/networkSecurityGroups/providers/diagnosticSettings"
#                 roleDefinitionIds = [
#                   "/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa", // Monitoring Contributor
#                   "/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab"  // Storage Account Contributor
#                 ]
#                 existenceCondition = {
#                   allOf = [
#                     {
#                       field = "Microsoft.Network/networkSecurityGroups/providers/diagnosticSettings/logs[*].category"
#                       equals = "NetworkSecurityGroupEvent"
#                     },
#                     {
#                       field = "Microsoft.Network/networkSecurityGroups/providers/diagnosticSettings/logs.enabled"
#                       equals = "true"
#                     },
#                     {
#                       field = "Microsoft.Network/networkSecurityGroups/providers/diagnosticSettings.storageAccountId"
#                       exists = true
#                     }
#                   ]
#                 }
#                 deployment = {
#                   properties = {
#                     mode = "incremental"
#                     parameters = {
#                       resourceName = {
#                         value = "[field('name')]"
#                       }
#                       location = {
#                         value = "[field('location')]"
#                       }
#                       storageAccountId = {
#                         value = "[parameters('storageAccountIds')[field('location')]]"
#                       }
#                     }
#                     template = {
#                       "$schema" = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
#                       contentVersion = "1.3.0.0"
#                       parameters = {
#                         resourceName = {
#                           type = "string"
#                         }
#                         location = {
#                           type = "string"
#                         }
#                         storageAccountId = {
#                           type = "string"
#                         }
#                       }
#                       resources = [
#                         {
#                           type = "Microsoft.Network/networkSecurityGroups/providers/diagnosticSettings"
#                           apiVersion = "2021-05-01-preview"
#                           name = "[concat(parameters('resourceName'), '-NSG-FlowLogs')]"
#                           location = "[parameters('location')]"
#                           properties = {
#                             storageAccountId = "[parameters('storageAccountId')]"
#                             logs = [
#                               {
#                                 category = "NetworkSecurityGroupEvent"
#                                 enabled = true
#                               }
#                             ]
#                           }
#                         }
#                       ]
#                     }
#                   }
#                 }
#               }
#             }
#           ]
#         },
#         {
#           field = "location"
#           notIn = "[parameters('allowedLocations')]"
#           effect = "Audit"
#         }
#       ]
#     }
#   })
# }
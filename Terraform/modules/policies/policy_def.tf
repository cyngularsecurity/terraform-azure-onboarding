
# # resource "azapi_resource" "symbolicname" {
# #   type = "Microsoft.Authorization/policyDefinitions@2023-04-01"
# #   name = "string"
# #   parent_id = "string"
# #   body = jsonencode({
# #     properties = {
# #       description = "string"
# #       displayName = "string"
# #       mode = "string"
# #       parameters = {
# #         {customized property} = {
# #           allowedValues = [ object ]
# #           metadata = {
# #             assignPermissions = bool
# #             description = "string"
# #             displayName = "string"
# #             strongType = "string"
# #           }
# #           type = "string"
# #         }
# #       }
# #       policyType = "string"
# #       version = "string"
# #       versions = [
# #         "string"
# #       ]
# #       # policyRule = {

# #       # }
# #     }
# #   })
# # }

# resource "null_resource" "unyamelize" {
#   triggers = {
#     yaml_file = "${file("${path.module}/policy_def.yaml")}"
#   }

#   provisioner "local-exec" {
#     interpreter = ["bash", "-c"]
#     command     = <<-EOT
#       yq eval -o=json ${path.module}/policy_def.yaml > ${path.module}/policy_def.json
#     EOT
#   }
# }

# resource "azurerm_policy_definition" "diagnostic_settings_policy" {
#   name         = "apply-diagnostic-settings"
#   policy_type  = "Custom"
#   mode         = "All"
#   display_name = "Apply diagnostic settings to all resources"
#   description  = "Ensure that diagnostic settings are applied to all resources in the subscription."

#   # policy_rule = file("${path.module}/policy-definition.json")

#   policy_rule = <<POLICY_RULE
# {
#   "if": {
#     "field": "type",
#     "in": [
#       "Microsoft.Compute/virtualMachines",
#       "Microsoft.Network/networkInterfaces",
#       "Microsoft.Storage/storageAccounts",
#       "Microsoft.Sql/servers"
#       // Add other resource types as needed
#     ]
#   },
#   "then": {
#     "effect": "DeployIfNotExists",
#     "details": {
#       "type": "Microsoft.Insights/diagnosticSettings",
#       "name": "set-diagnostic-settings",
#       "existenceCondition": {
#         "allOf": [
#           {
#             "field": "Microsoft.Insights/diagnosticSettings/logs.enabled",
#             "equals": "true"
#           },
#           {
#             "field": "Microsoft.Insights/diagnosticSettings/metrics.enabled",
#             "equals": "true"
#           },
#           {
#             "field": "Microsoft.Insights/diagnosticSettings/storageAccountId",
#             "equals": "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{storageAccountName}"
#           },
#         ]
#       },
#       "deployment": {
#         "properties": {
#           "mode": "incremental",
#           "template": {
#             "$schema": "http://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#",
#             "contentVersion": "1.0.0.0",
#             "resources": [
#               {
#                 "type": "Microsoft.Insights/diagnosticSettings",
#                 "apiVersion": "2021-05-01-preview",
#                 "name": "set-diagnostic-settings",
#                 "properties": {
#                   "storageAccountId": "[parameters('storageAccountId')]",
#                   "logs": [
#                     {
#                       "category": "Administrative",
#                       "enabled": true,
#                       "retentionPolicy": {
#                         "enabled": false,
#                         "days": 0
#                       }
#                     },
#                     {
#                       "category": "AuditEvent",
#                       "enabled": true,
#                       "retentionPolicy": {
#                         "enabled": false,
#                         "days": 0
#                       }
#                     }
#                   ]
#                 }
#               }
#             ],
#             "parameters": {
#               "storageAccountId": {
#                 "type": "string"
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }
# POLICY_RULE

#   parameters = <<PARAMETERS
# {
#   "categories": {
#     "type": "Array",
#     "metadata": {
#       "displayName": "Log Categories",
#       "description": "List of categories to enable diagnostics for"
#     }
#   },
#   "storageAccountId": {
#     "type": "String",
#     "metadata": {
#       "description": "ID of the storage account to use for diagnostic settings"
#     }
#   }
# }
# PARAMETERS
# }

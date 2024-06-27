
# resource "azurerm_policy_definition" "activity_logs_diagnostic_settings" {
#   count = var.enable_activity_logs ? 1 : 0

#   policy_type = "Custom"
#   mode        = "All"

#   name                = format("cyngular-%s-activity-logs-def", var.client_name)
#   display_name        = "Cyngular ${var.client_name} Activity logs Definition"
#   description         = "Ensures that Activity logs diagnostic settings configured for subscription to send logs to the specified storage account."
#   management_group_id = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"

#   policy_rule = jsonencode({
#     if = {
#       field  = "type"
#       equals = "Microsoft.Resources/subscriptions"
#     },
#     then = {
#       effect = "DeployIfNotExists",
#       details = {
#         roleDefinitionIds = [
#           "/providers/Microsoft.Authorization/roleDefinitions/ac63b705-f282-497d-ac71-919bf39d939d", // mgmt group reader
#           "/providers/microsoft.authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c", // Contributor
#           "/providers/Microsoft.Authorization/roleDefinitions/ccca81f6-c8dc-45e2-8833-a5e13f9ae238", // Monitoring Contributor
#           "/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab"  // Storage Account Contributor
#         ],
#         deploymentScope = "Subscription"
#         existenceScope  = "Subscription"
#         type            = "Microsoft.Insights/diagnosticSettings",
#         existenceCondition = {
#           allOf = [
#             {
#               allOf = [
#                 {
#                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].enabled"
#                   equals = "true"
#                 },
#                 {
#                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
#                   equals = "Administrative"
#                 }
#               ]
#             },
#             {
#               allOf = [
#                 {
#                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].enabled"
#                   equals = "true"
#                 },
#                 {
#                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
#                   equals = "Autoscale"
#                 }
#               ]
#             },
#             {
#               allOf = [
#                 {
#                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].enabled"
#                   equals = "true"
#                 },
#                 {
#                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
#                   equals = "ResourceHealth"
#                 }
#               ]
#             },
#             {
#               allOf = [
#                 {
#                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].enabled"
#                   equals = "true"
#                 },
#                 {
#                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
#                   equals = "Recommendation"
#                 }
#               ]
#             },
#             {
#               allOf = [
#                 {
#                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].enabled"
#                   equals = "true"
#                 },
#                 {
#                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
#                   equals = "Alert"
#                 }
#               ]
#             },
#             {
#               allOf = [
#                 {
#                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].enabled"
#                   equals = "true"
#                 },
#                 {
#                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
#                   equals = "ServiceHealth"
#                 }
#               ]
#             },
#             {
#               allOf = [
#                 {
#                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].enabled"
#                   equals = "true"
#                 },
#                 {
#                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
#                   equals = "Security"
#                 }
#               ]
#             },
#             {
#               allOf = [
#                 {
#                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].enabled"
#                   equals = "true"
#                 },
#                 {
#                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
#                   equals = "Policy"
#                 }
#               ]
#             }
#           ]
#         }
#         deployment = {
#           location = "${var.main_location}"
#           properties = {
#             mode = "incremental",
#             parameters = {
#               subscription = {
#                 value = "[subscription().subscriptionId]"
#               }
#               location = {
#                 value = "[field('location')]"
#               }
#               StorageAccountID = {
#                 value = "[parameters('StorageAccountID')]"
#               }
#             }
#             template = {
#               "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
#               contentVersion = "1.3.0.0"
#               parameters = {
#                 subscription = {
#                   type = "string"
#                 }
#                 location = {
#                   type = "string"
#                 }
#                 StorageAccountID = {
#                   type = "string"
#                 }
#               }
#               resources = [
#                 {
#                   name       = "[concat('monitor-', parameters('subscription'), '-activity-logs')]"
#                   type       = "Microsoft.Insights/diagnosticSettings"
#                   apiVersion = "2021-05-01-preview"
#                   location   = "Global"
#                   properties = {
#                     StorageAccountID = "[parameters('StorageAccountID')]"
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
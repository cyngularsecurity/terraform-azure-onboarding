
# resource "azurerm_policy_definition" "audit_event_diagnostic_settings" {
#   count = var.enable_audit_events_logs ? 1 : 0

#   policy_type = "Custom"
#   mode        = "Indexed"

#   name                = format("cyngular-%s-audit-event-def", var.client_name)
#   display_name        = "Cyngular ${var.client_name} Audit Event Definition"
#   description         = "Cyngular diagnostic settings deployment for resources various categories"
#   management_group_id = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"

#   policy_rule = jsonencode({
#     if = {
#       allOf = [
#         {
#           field = "type",
#           notIn = "[parameters('blacklistedTypes')]"
#         },
#         {
#           field = "location",
#           in = "[parameters('ClientLocations')]"
#         }
#       ]
#     },
#     then = {
#       effect = "DeployIfNotExists",
#       details = {
#         roleDefinitionIds = [
#           "/providers/microsoft.authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c", // Contributor
#           "/providers/Microsoft.Authorization/roleDefinitions/ccca81f6-c8dc-45e2-8833-a5e13f9ae238", // Monitoring Contributor
#           "/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab"  // Storage Account Contributor
#         ],
#         type = "Microsoft.Insights/diagnosticSettings",
        # existenceCondition = {
        #   anyOf = [
        #     {
        #       allOf = [
        #         { // to deploy AllLogs category diagnostic settings on supported, from list A -- 1
        #           field = "type",
        #           in    = "[parameters('typeListA')]"
        #         },
        #         {
        #           count = {
        #             field = "Microsoft.Insights/diagnosticSettings/logs[*]",
        #             where = {
        #               allOf = [
        #                 {
        #                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].enabled",
        #                   equals = true
        #                 },
        #                 {
        #                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].categoryGroup",
        #                   equals = "AllLogs"
        #                 },
        #                 {
        #                   field  = "Microsoft.Insights/diagnosticSettings/storageAccountId"
        #                   equals = "[parameters('storageAccountIds')[field('location')]]"
        #                 }
        #               ]
        #             }
        #           },
        #           equals = 1
        #         }
        #       ]
        #     },
        #     {
        #       allOf = [
        #         { // to deploy AllLogs, Audit categories diagnostic settings on supported, from list B -- 2
        #           field = "type",
        #           in    = "[parameters('typeListB')]"
        #         },
        #         {
        #           count = {
        #             field = "Microsoft.Insights/diagnosticSettings/logs[*]",
        #             where = {
        #               allOf = [
        #                 {
        #                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].enabled",
        #                   equals = true
        #                 },
        #                 {
        #                   field = "Microsoft.Insights/diagnosticSettings/logs[*].categoryGroup",
        #                   in    = ["AllLogs", "Audit"]
        #                 },
        #                 {
        #                   field  = "Microsoft.Insights/diagnosticSettings/storageAccountId"
        #                   equals = "[parameters('storageAccountIds')[field('location')]]"
        #                 }
        #               ]
        #             }
        #           },
        #           equals = 2
        #         }
        #       ]
        #     },
        #     {
        #       allOf = [
        #         { // to deploy AuditEvent category diagnostic settings on all other resources supporting DS, if are not in specified lists -- Default
        #           not = {
        #             field = "type"
        #             in    = "[concat(parameters('typeListA'), parameters('typeListB'))]"
        #           }
        #         },
        #         {
        #           count = {
        #             field = "Microsoft.Insights/diagnosticSettings/logs[*]",
        #             where = {
        #               allOf = [
        #                 {
        #                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].enabled",
        #                   equals = true
        #                 },
        #                 {
        #                   field  = "Microsoft.Insights/diagnosticSettings/logs[*].category",
        #                   equals = "AuditEvent"
        #                 },
        #                 {
        #                   field  = "Microsoft.Insights/diagnosticSettings/storageAccountId"
        #                   equals = "[parameters('storageAccountIds')[field('location')]]"
        #                 }
        #               ]
        #             }
        #           },
        #           equals = 1
        #         }
        #       ]
        #     }
        #   ]
        # }
#         deployment = {
#           properties = {
#             mode = "incremental"
#             parameters = {
#               resourceName = {
#                 value = "[field('name')]"
#               }
#               resourceId = {
#                 value = "[field('id')]"
#               }
#               location = {
#                 value = "[field('location')]"
#               }
#               storageAccountId = {
#                 value = "[parameters('StorageAccountIds')[field('location')]]"
#               }
#               logsConfiguration = {
#                 value = "[if(contains(parameters('typeListA'), field('type')), 'AllLogs', if(contains(parameters('typeListB'), field('type')), 'AllLogs,Audit', 'AuditEvent'))]"
#               }
#             }
#             template = {
#               "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
#               contentVersion = "1.3.0.0"
#               parameters = {
#                 resourceName = {
#                   type = "string"
#                 }
#                 resourceId = {
#                   type = "string"
#                 }
#                 location = {
#                   type = "string"
#                 }
#                 storageAccountId = {
#                   type = "string"
#                 }
#                 logsConfiguration = {
#                   type = "list"
#                 }
#               }
#               resources = [
#                 {
#                   type       = "Microsoft.Insights/diagnosticSettings"
#                   apiVersion = "2021-05-01-preview"
#                   name       = "[concat(parameters('resourceName'), '-diagnostics')]"
#                   location   = "[parameters('location')]"
#                   scope = "[parameters('resourceId')]"
#                   properties = {
#                     storageAccountId = "[parameters('storageAccountId')]"
#                     logs = [
#                       {
#                         categoryGroup = "[parameters('logsConfiguration')]"
#                         enabled       = true
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
#   metadata = jsonencode({
#     category = "Cyngular"
#     version = "3.0.1"
#   })
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
#         description = "The list of allowed locations for Resources."
#         displayName = "Allowed Locations"
#       }
#     }
#     blacklistedTypes = {
#       type = "Array"
#       metadata = {
#         displayName = "Resource Types"
#         description = "List of Azure resource types not supporting diagnostics settings."
#       }
#     }
#     typeListA = {
#       type = "Array",
#       metadata = {
#         description = "List of resource types to check for AllLogs category"
#       }
#     },
#     typeListB = {
#       type = "Array",
#       metadata = {
#         description = "List of resource types to check for AllLogs and Audit categories"
#       }
#     }
#   })
# }
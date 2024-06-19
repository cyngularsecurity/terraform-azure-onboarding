
resource "azurerm_policy_definition" "audit_event_diagnostic_settings" {
  count                = var.enable_audit_events_logs ? 1 : 0

  name         = "cyngular-${var.client_name}-audit-event-diagnostic-settings-def"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Cyngular ${var.client_name} Audit Event - over resources"
  description  = "Cyngular diagnostic settings deployment for resources various categories"

  metadata = jsonencode({ category = "Monitoring" })
  parameters = jsonencode({
    StorageAccountIds = {
      type = "Object"
      metadata = {
        description = "A map of locations to storage account IDs where the logs should be sent."
        displayName = "Storage Account Map"
      }
    }
    ClientLocations = {
      type = "Array"
      metadata = {
        description = "The list of allowed locations for AKS clusters."
        displayName = "Allowed Locations"
      }
    }
    resourceTypes = {
      type = "Array"
      metadata = {
        displayName = "Resource Types"
        description = "List of Azure resource types to apply the policy."
      }
    }
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field = "type"
          in    = "[parameters('resourceTypes')]"
        },
        {
          field = "location"
          in    = "[parameters('ClientLocations')]"
        }
      ]
    }
    then = {
      effect = "deployIfNotExists"
      details = {
        type = "Microsoft.Insights/diagnosticSettings"
        roleDefinitionIds = [
          "/providers/Microsoft.Authorization/roleDefinitions/ccca81f6-c8dc-45e2-8833-a5e13f9ae238",  // Monitoring Contributor
          "/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab"   // Storage Account Contributor
        ]
        existenceCondition = {
          allOf = [
            # {
            #   field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
            #   equals = "AllLogs"
            # },
            {
              field  = "Microsoft.Insights/diagnosticSettings/logs[*].enabled"
              equals = "true"
            },
            {
              field  = "Microsoft.Insights/diagnosticSettings/storageAccountId"
              exists = true
            }
          ]
        }
        deployment = {
          properties = {
            mode = "incremental"
            parameters = {
              resourceName = {
                value = "[field('name')]"
              }
              resourceId = {
                value = "[field('id')]"
              }
              location = {
                value = "[field('location')]"
              }
              storageAccountId = {
                value = "[parameters('StorageAccountIds')[field('location')]]"
              }
            }
            template = {
              "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
              contentVersion = "1.3.0.0"
              parameters = {
                resourceName = {
                  type = "string"
                }
                resourceId = {
                  type = "string"
                }
                location = {
                  type = "string"
                }
                storageAccountId = {
                  type = "string"
                }
              }
              resources = [
                {
                  type       = "Microsoft.Insights/diagnosticSettings"
                  apiVersion = "2021-05-01-preview"
                  name       = "[concat(parameters('resourceName'), '-diagnostics')]"
                  # location   = "[parameters('location')]"
                  scope = "[parameters('resourceId')]"
                  properties = {
                    storageAccountId = "[parameters('storageAccountId')]"
                    logs = [
                      {
                        categoryGroup = "AllLogs"
                        enabled  = true
                      }
                    ]
                  }
                }
              ]
            }
          }
        }
      }
    }
  })
}
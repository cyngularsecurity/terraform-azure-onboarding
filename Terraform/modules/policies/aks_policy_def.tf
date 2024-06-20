resource "azurerm_policy_definition" "aks_diagnostic_settings" {
  count        = var.enable_aks_logs ? 1 : 0
  name         = "cyngular-${var.client_name}-aks-diagnostic-settings-def"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Cyngular ${var.client_name} AKS - Require Diagnostic Settings for Clusters"
  description  = "Ensures that AKS clusters have diagnostic settings configured to send logs to the specified storage account."
  # description = "This policy applies diagnostic settings to AKS clusters only if they are created in specified locations."

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
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.ContainerService/managedClusters"
        },
        {
          field = "location"
          in    = "[parameters('ClientLocations')]"
        }
      ]
    },
    then = {
      effect = "DeployIfNotExists"
      details = {
        type = "Microsoft.ContainerService/managedClusters/providers/diagnosticSettings"
        # type = "Microsoft.Insights/diagnosticSettings"
        # # deploymentScope = "subscription"
        # existenceScope = "resourceGroup"
        roleDefinitionIds = [
          "/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa", // monitoring contributor
          "/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab", // storage account contributor
        ]
        existenceCondition = {
          allOf = [
            {
              field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
              equals = "kube-audit"
            },
            {
              field  = "Microsoft.Insights/diagnosticSettings/logs.enabled" // Microsoft.Insights/diagnosticSettings/logs[*].enabled
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
                # value = "[if(contains(parameters('StorageAccountIds'), field('location')), parameters('StorageAccountIds')[field('location')], 'disabled')]"
              }
            }
            template = {
              "$schema" = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
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
                  type = "Microsoft.Insights/diagnosticSettings"
                  apiVersion = "2021-05-01-preview"
                  name       = "[concat(parameters('resourceName'), '-AKS-DS')]"
                  scope      = "[parameters('resourceId')]"
                  # location = "[parameters('location')]"
                  properties = {
                    storageAccountId = "[parameters('storageAccountId')]"
                    logs = [
                      {
                        category = "kube-audit"
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

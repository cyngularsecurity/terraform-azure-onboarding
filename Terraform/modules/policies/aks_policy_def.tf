resource "azurerm_policy_definition" "aks_diagnostic_settings" {
  name         = "require-aks-diagnostic-settings"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Cyngular ${var.client_name} Require Diagnostic Settings for AKS Clusters"
  description  = "Ensures that AKS clusters have diagnostic settings configured to send logs to the specified storage account."

  metadata = jsonencode({ category = "Monitoring" })

  parameters = jsonencode({
    storageAccountIds = {
      type = "Object"
      metadata = {
        description = "A map of locations to storage account IDs where the logs should be sent."
        displayName = "Storage Account Map"
      }
    }
    allowedLocations = {
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
          in    = "[parameters('allowedLocations')]"
        }
      ]
    },
    then = {
      effect = "DeployIfNotExists"
      details = {
        type = "Microsoft.Insights/diagnosticSettings"
        # roleDefinitionIds = [
        #   "/providers/Microsoft.Authorization/roleDefinitions/yourRoleDefinitionId" # Replace with appropriate Role Definition ID
        # ]
        deployment = {
          properties = {
            mode = "incremental"
            parameters = {
              storageAccountId = {
                value = "[parameters('storageAccountIds')[field('location')]]"
              }
            }
            template = {
              "$schema" = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
              contentVersion = "1.4.3.2"
              parameters = {
                storageAccountId = {
                  type = "string"
                }
              }
              resources = [
                {
                  type = "Microsoft.Insights/diagnosticSettings"
                  apiVersion = "2021-05-01-preview"
                  name = "[concat(field('name'), '-diagnosticSettings')]"
                  # location = "[field('location')]"
                  properties = {
                    logs = [
                      {
                        category = "kube-audit"
                        enabled = true
                      }
                    ]
                    storageAccountId = "[parameters('storageAccountId')]"
                    # storageAccountId = "[parameters('storageAccountIds')[field('location')]]"
                  }
                }
              ]
            }
          }
        }
        existenceCondition = {
          allOf = [
            {
              field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
              equals = "kube-audit"
            },
            {
              field  = "Microsoft.Insights/diagnosticSettings/logs.enabled"
              equals = "true"
            },
            {
              field = "Microsoft.Insights/diagnosticSettings/storageAccountId"
              exists = true
            }
          ]
        }
      }
    }
  })
  # policy_rule = jsonencode({
  #   if = {
  #     allOf = [
  #       {
  #         field  = "type"
  #         equals = "Microsoft.ContainerService/managedClusters"
  #       },
  #       {
  #         field = "location"
  #         in    = "[parameters('allowedLocations')]"
  #       }
  #     ]
  #   }
  #   then = {
  #     effect = "AuditIfNotExists"
  #     details = {
  #       type = "Microsoft.Insights/diagnosticSettings"
  #       existenceCondition = {
  #         allOf = [
  #           {
  #             field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
  #             equals = "kube-audit"
  #           },
  #           {
  #             field  = "Microsoft.Insights/diagnosticSettings/logs.enabled"
  #             equals = "true"
  #           },
  #           {
  #             field = "Microsoft.Insights/diagnosticSettings/storageAccountId"
  #             equals    = "[parameters('storageAccountIds')[current('location')]]"

  #             # equals    = "[parameters('storageAccountIds')[field('location')]]"
  #           }
  #         ]
  #       }
  #     }
  #   }
  # })
}

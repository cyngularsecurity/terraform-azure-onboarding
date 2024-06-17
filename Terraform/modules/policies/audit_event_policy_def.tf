
resource "azurerm_policy_definition" "audit_event_diagnostic_settings" {
  name         = "require-diagnostic-settings"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Ensure diagnostics settings are configured for resources to storage accounts in the same region"
  description  = "This policy ensures that diagnostics settings are configured to write logs to a storage account in the same region as the monitored Azure resource."
  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field = "type"
          in = "[parameters('resourceTypes')]"
        },
        {
          field = "location"
          equals = "[parameters('location')]"
        }
      ]
    }
    then = {
      effect = "deployIfNotExists"
      details = {
        type = "Microsoft.Insights/diagnosticSettings"
        roleDefinitionIds = [
          "/providers/Microsoft.Authorization/roleDefinitions/StorageAccountContributor"
        ]
        deployment = {
          properties = {
            mode = "incremental"
            parameters = {
              resourceName = {
                value = "[field('name')]"
              }
              location = {
                value = "[field('location')]"
              }
              storageAccountId = {
                value = "[parameters('storageAccountID')]"
              }
            }
            template = {
              "$schema" = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
              contentVersion = "1.0.0.0"
              parameters = {
                resourceName = {
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
                  apiVersion = "2017-05-01-preview"
                  name = "[concat(parameters('resourceName'), '-diagnostics')]"
                  location = "[parameters('location')]"
                  properties = {
                    storageAccountId = "[parameters('storageAccountId')]"
                    logs = [
                      {
                        category = "AllLogs"
                        enabled = true
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
  parameters = jsonencode({
    location = {
      type = "String"
      metadata = {
        displayName = "location"
        description = "Location where storage account will be deployed"
      }
    }
    resourceTypes = {
      type = "Array"
      metadata = {
        displayName = "Resource Types"
        description = "List of Azure resource types to apply the policy."
        defaultValue = [
          "Microsoft.KeyVault/vaults",
          "Microsoft.ContainerService/managedClusters",
          "Microsoft.Network/networkSecurityGroups"
        ]
      }
    }
    storageAccountID = {
      type = "String"
      metadata = {
        displayName = "Storage Account"
        description = "storage account ID"
        defaultValue = "/subscriptions/b6c14413-fb13-4063-acd5-d47e2537a7ba/resourceGroups/cyngular-asos-rg/providers/Microsoft.Storage/storageAccounts/cyngularasoswesteurope"
      }
    }
  })
  metadata = jsonencode({
    category = "Monitoring"
  })
}

resource "azurerm_policy_definition" "activity_logs_diagnostic_settings" {
  name         = "cyngular-activity-logs"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "apply activity logs per subscription"
  description  = "cyngular diagnostic settings deployment of subscription"

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
                        category = "Recommendation"
                        enabled = true
                      },
                      {
                        category = "Alert"
                        enabled = true
                      },
                      {
                        category = "ServiceHealth"
                        enabled = true
                      },
                      {
                        category = "Administrative"
                        enabled = true
                      },
                      {
                        category = "Security"
                        enabled = true
                      },
                      {
                        category = "Policy"
                        enabled = true
                      },
                      {
                        category = "Autoscale"
                        enabled = true
                      },
                      {
                        category = "ResourceHealth"
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
    storageAccountID = {
      type = "String"
      metadata = {
        displayName = "Storage Account"
        description = "storage account ID"
        defaultValue = var.default_storage_accounts[var.main_location]
      }
    }
  })
  metadata = jsonencode({
    category = "Monitoring"
  })
}
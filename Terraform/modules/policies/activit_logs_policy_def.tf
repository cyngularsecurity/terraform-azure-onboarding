
resource "azurerm_policy_definition" "activity_logs_diagnostic_settings" {
  count                = var.enable_activity_logs ? 1 : 0

  name         = "cyngular-${var.client_name}-activity-logs-diagnostic-settings-def"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Cyngular ${var.client_name} Activity logs - over subscription"
  description  = "cyngular diagnostic settings deployment for subscription Activity logs"

  metadata = jsonencode({ category = "Monitoring" })
  parameters = jsonencode({
    subscription = {
      type = "String"
      metadata = {
        displayName = "Subscription ID"
        description = "Id of subscription scope the policy will be assigned to"
      }
    }
    StorageAccountID = {
      type = "String"
      metadata = {
        displayName = "Storage Account"
        description = "storage account ID"
      }
    }
  })

  policy_rule = jsonencode({
    if = {
      field  = "type"
      equals = "Microsoft.Resources/subscriptions"
    },
    then = {
      effect = "deployIfNotExists"
      details = {
        type = "Microsoft.Insights/diagnosticSettings"
        existenceCondition = {
          allOf = [
            {
              field  = "Microsoft.Insights/diagnosticSettings/logs[*].enabled"
              equals = "true"
            },
            {
              field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
              equals = "Administrative"
            },
            {
              field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
              equals = "Autoscale"
            },
            {
              field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
              equals = "Policy"
            },
            {
              field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
              equals = "Security"
            },
            {
              field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
              equals = "ServiceHealth"
            },
            {
              field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
              equals = "Alert"
            },
            {
              field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
              equals = "Recommendation"
            },
            {
              field  = "Microsoft.Insights/diagnosticSettings/logs[*].category"
              equals = "ResourceHealth"
            }
          ]
        },
        roleDefinitionIds = [
          "/providers/Microsoft.Authorization/roleDefinitions/StorageAccountContributor",
          "/providers/Microsoft.Authorization/roleDefinitions/ccca81f6-c8dc-45e2-8833-a5e13f9ae238" // monitoring contributor
        ]
        deployment = {
          properties = {
            mode = "incremental"
            parameters = {
              subscription = {
                value = "[parameters('subscription')]"
              }
              location = {
                value = "[field('location')]"
              }
              StorageAccountID = {
                value = "[parameters('StorageAccountID')]"
              }
            }
            template = {
              "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
              contentVersion = "1.0.0.0"
              parameters = {
                subscription = {
                  type = "string"
                }
                location = {
                  type = "string"
                }
                StorageAccountID = {
                  type = "string"
                }
              }
              resources = [
                {
                  type       = "Microsoft.Insights/diagnosticSettings"
                  apiVersion = "2017-05-01-preview"
                  name       = "[concat(parameters('subscription'), '-activity-logs')]"
                  location   = "[parameters('location')]"
                  properties = {
                    StorageAccountID = "[parameters('StorageAccountID')]"
                    logs = [
                      {
                        category = "Recommendation"
                        enabled  = true
                        retentionPolicy = {
                          enabled = false
                          days    = 30
                        }
                      },
                      {
                        category = "Alert"
                        enabled  = true
                      },
                      {
                        category = "ServiceHealth"
                        enabled  = true
                      },
                      {
                        category = "Administrative"
                        enabled  = true
                      },
                      {
                        category = "Security"
                        enabled  = true
                      },
                      {
                        category = "Policy"
                        enabled  = true
                      },
                      {
                        category = "Autoscale"
                        enabled  = true
                      },
                      {
                        category = "ResourceHealth"
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
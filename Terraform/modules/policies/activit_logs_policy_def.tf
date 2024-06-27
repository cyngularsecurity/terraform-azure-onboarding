
resource "azurerm_policy_definition" "activity_logs" {
  count = var.enable_activity_logs ? 1 : 0

  policy_type = "Custom"
  mode        = "All"

  name                = format("cyngular-%s-activity-logs-def", var.client_name)
  display_name        = "Cyngular ${var.client_name} Activity logs Definition"
  description         = "Ensures that Activity logs diagnostic settings configured for subscription to send logs to the specified storage account."
  management_group_id = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"

  policy_rule = jsonencode({
    if = {
      field  = "type"
      equals = "Microsoft.Resources/subscriptions"
    },
    then = {
      effect = "DeployIfNotExists",
      details = {
        roleDefinitionIds = [
          "${azurerm_role_definition.policy_assignment_def[0].role_definition_resource_id}",
          "/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa", // Monitoring Contributor
          "/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab"  // Storage Account Contributor
        ],
        deploymentScope = "Subscription"
        existenceScope  = "Subscription"
        type            = "Microsoft.Insights/diagnosticSettings",
        existenceCondition = {
          count = {
            field = "Microsoft.Insights/diagnosticSettings/logs[*]",
            where = {
              allOf = [
                {
                  field  = "Microsoft.Insights/diagnosticSettings/logs[*].category",
                  in = [
                    "Administrative",
                    "Security",
                    "Alert",
                    "Recommendation",
                    "Policy",
                    "Autoscale",
                    "ResourceHealth",
                    "ServiceHealth"
                  ]
                },
                {
                  field  = "Microsoft.Insights/diagnosticSettings/logs[*].enabled",
                  equals = "true"
                },
                {
                  field  = "Microsoft.Insights/diagnosticSettings/storageAccountId"
                  equals = "[parameters('StorageAccountID')]"
                }
              ]
            }
          },
          equals = 8
        },
        deployment = {
          location = "${var.main_location}"
          properties = {
            mode = "incremental",
            parameters = {
              StorageAccountID = {
                value = "[parameters('StorageAccountID')]"
              }
              subscription = {
                value = "[subscription().subscriptionId]"
              }
            }
            template = {
              "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
              contentVersion = "3.0.1.0"
              parameters = {
                StorageAccountID = {
                  type = "string"
                }
                subscription = {
                  type = "string"
                }
              }
              resources = [
                {
                  name       = "[concat('monitor-', parameters('subscription'), '-activity-logs')]"
                  type       = "Microsoft.Insights/diagnosticSettings"
                  apiVersion = "2021-05-01-preview"
                  location   = "Global"
                  properties = {
                    StorageAccountID = "[parameters('StorageAccountID')]"
                    logs = [
                      {
                        category = "Recommendation"
                        enabled  = true
                        # retentionPolicy = {
                        #   enabled = false
                        #   days    = 30
                        # }
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
  metadata = jsonencode({
    category = "Cyngular - Activity Logs"
    version = "3.0.1"
  })
  parameters = jsonencode({
    StorageAccountID = {
      type = "String"
      metadata = {
        displayName = "Storage Account"
        description = "storage account ID"
      }
    }
  })
}
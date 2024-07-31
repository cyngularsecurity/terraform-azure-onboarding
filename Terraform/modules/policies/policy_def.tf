

resource "azurerm_policy_definition" "diagnostic_settings_policy" {
  name         = "apply-diagnostic-settings"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Apply diagnostic settings to all resources"
  description  = "Ensure that diagnostic settings are applied to all resources in the subscription."

  policy_rule = <<POLICY_RULE
{
  "if": {
    "anyOf": [
      {
        "field": "type",
        "equals": "Microsoft.Compute/virtualMachines"
      },
    "field": "type",
    "in": [
      "Microsoft.Compute/virtualMachines",
      "Microsoft.Network/networkInterfaces",
      "Microsoft.Storage/storageAccounts",
      "Microsoft.Sql/servers"
      // Add other resource types as needed
    ]
  },
  "then": {
    "effect": "DeployIfNotExists",
    "details": {
      "type": "Microsoft.Insights/diagnosticSettings",
      "name": "set-diagnostic-settings",
      "existenceCondition": {
        "field": "Microsoft.Insights/diagnosticSettings/storageAccountId",
        "equals": "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{storageAccountName}"
      },
      "deployment": {
        "properties": {
          "mode": "incremental",
          "template": {
            "$schema": "http://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#",
            "contentVersion": "1.0.0.0",
            "resources": [
              {
                "type": "Microsoft.Insights/diagnosticSettings",
                "apiVersion": "2021-05-01-preview",
                "name": "set-diagnostic-settings",
                "properties": {
                  "storageAccountId": "[parameters('storageAccountId')]",
                  "logs": [
                    {
                      "category": "Administrative",
                      "enabled": true,
                      "retentionPolicy": {
                        "enabled": false,
                        "days": 0
                      }
                    }
                  ]
                }
              }
            ],
            "parameters": {
              "storageAccountId": {
                "type": "string"
              }
            }
          }
        }
      }
    }
  }
}
POLICY_RULE

  parameters = <<PARAMETERS
{
  "storageAccountId": {
    "type": "String",
    "metadata": {
      "description": "ID of the storage account to use for diagnostic settings"
    }
  }
}
PARAMETERS
}

resource "azurerm_policy_assignment" "diagnostic_settings_assignment" {
  name                 = "apply-diagnostic-settings"
  policy_definition_id = azurerm_policy_definition.diagnostic_settings_policy.id
  scope                = "/subscriptions/${var.subscription_id}"
  display_name         = "Apply diagnostic settings to all resources"
  description          = "Ensure that diagnostic settings are applied to all resources in the subscription."

  parameters = <<PARAMETERS
{
  "storageAccountId": {
    "value": "${var.storage_account_id}"
  }
}
PARAMETERS
}

resource "azurerm_policy_definition" "diagnostic_settings_policy" {
  name         = "diagnostic-settings-policy"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Enforce Diagnostic Settings"
  policy_rule  = <<POLICY_RULE
{
  "if": {
    "field": "type",
    "in": [
      "Microsoft.Compute/virtualMachines",
      "Microsoft.Network/networkSecurityGroups",
      "Microsoft.Storage/storageAccounts"
    ]
  },
  "then": {
    "effect": "DeployIfNotExists",
    "details": {
      "type": "Microsoft.Insights/diagnosticSettings",
      "name": "set-diagnostic-settings",
      "existenceCondition": {
        "allOf": [
          {
            "field": "Microsoft.Insights/diagnosticSettings/logs.enabled",
            "equals": "true"
          },
          {
            "field": "Microsoft.Insights/diagnosticSettings/metrics.enabled",
            "equals": "true"
          }
        ]
      },
      "roleDefinitionIds": [
        "/providers/Microsoft.Authorization/roleDefinitions/MonitoringContributor"
      ],
      "deployment": {
        "properties": {
          "mode": "incremental",
          "template": {
            "$schema": "http://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
            "contentVersion": "1.0.0.0",
            "resources": [
              {
                "type": "Microsoft.Insights/diagnosticSettings",
                "apiVersion": "2017-05-01-preview",
                "name": "[concat(parameters('resourceName'), '/diagnosticSettings')]",
                "properties": {
                  "storageAccountId": "[parameters('storageAccountId')]",
                  "workspaceId": "[parameters('workspaceId')]",
                  "logs": [
                    {
                      "category": "AuditEvent",
                      "enabled": true,
                      "retentionPolicy": {
                        "enabled": false,
                        "days": 0
                      }
                    }
                  ],
                  "metrics": [
                    {
                      "category": "AllMetrics",
                      "enabled": true,
                      "retentionPolicy": {
                        "enabled": false,
                        "days": 0
                      }
                    }
                  ]
                }
              }
            ]
          },
          "parameters": {
            "resourceName": {
              "type": "string"
            },
            "storageAccountId": {
              "type": "string"
            },
            "workspaceId": {
              "type": "string"
            }
          }
        }
      }
    }
  }
}
POLICY_RULE
  parameters   = <<PARAMETERS
{
  "storageAccountId": {
    "type": "String",
    "metadata": {
      "displayName": "Storage Account ID",
      "description": "The ID of the storage account to send diagnostics logs to."
    }
  },
  "workspaceId": {
    "type": "String",
    "metadata": {
      "displayName": "Log Analytics Workspace ID",
      "description": "The ID of the Log Analytics workspace to send diagnostics logs to."
    }
  }
}
PARAMETERS
}
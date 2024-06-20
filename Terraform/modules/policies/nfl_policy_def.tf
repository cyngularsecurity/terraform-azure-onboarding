resource "azurerm_policy_definition" "nsg_flow_logs" {
  count        = var.enable_flow_logs ? 1 : 0

  name         = "cyngular-${var.client_name}-nsg-flow-logs-def"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Cyngular ${var.client_name} NSG Flow Logs - Apply flow logs on nsgs without"
  description  = "Ensures that NSG Flow Logs are configured to send logs to the specified storage account."

  metadata = jsonencode({ category = "Monitoring" })
  parameters = jsonencode({
    effect = {
      type = "String"
      metadata = {
        displayName = "effect"
        description = "Enable or disable the execution of the policy"
      }
      allowedValues = ["Audit", "DeployIfNotExists", "Disabled"]
      defaultValue = "DeployIfNotExists"
    }
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
          field = "type"
          equals = "Microsoft.Network/networkSecurityGroups"
        },
        {
          count = {
            field = "Microsoft.Network/networkSecurityGroups/flowLogs[*]"
          }
          equals = 0
        },
        {
          field = "location"
          in    = "[parameters('ClientLocations')]"
        }
      ]
    },
    then = {
      effect = "[parameters('effect')]",
      details = {
        roleDefinitionIds = [
          "/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa", // Monitoring Contributor
          "/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab"  // Storage Account Contributor
        ]
        type = "Microsoft.Network/networkWatchers/flowLogs"
        # type = "Microsoft.Network/networkSecurityGroups"
        # resourceGroupName = "NetworkWatcherRG",
        name = "[field('name')]" // fullName
        # name = "[concat('networkwatcher_', field('location'), '/flowLogs/', field('name'), '-NSG-Flow-Logs')]",
        # name = "[concat('networkwatcher_', field('location'), '/Microsoft.Network/', resourceGroup().name, field('name'))]",
        existenceCondition = {
          allOf = [
            {
              field = "Microsoft.Network/networkWatchers/flowLogs/targetResourceId",
              equals = "[concat(resourceGroup().id, '/providers/Microsoft.Network/networkSecurityGroups/', field('name'))]"
            },
            {
              field = "Microsoft.Network/networkWatchers/flowLogs/enabled"
              equals = "true"
            },
            {
              field = "Microsoft.Network/networkWatchers/flowLogs/storageId"
              exists = true
              # equals =  "[parameters('storageAccountIds')[field('location')]]"
            }
          ]
        },
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
              resourceId = {
                # value = "[field('id')]"
                value = "[concat(resourceGroup().id, '/providers/Microsoft.Network/networkSecurityGroups/', field('name'))]"
              }
              storageAccountId = {
                value = "[parameters('storageAccountIds')[field('location')]]"
              }
              nsgRG = {
                value = "[resourceGroup().name]"
              }
            }
            template = {
              "$schema" = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
              contentVersion = "1.3.0.0"
              parameters = {
                resourceName = {
                  type = "string"
                }
                location = {
                  type = "string"
                }
                resourceId = {
                  type = "string"
                }
                storageAccountId = {
                  type = "string"
                }
                nsgRG = {
                  type = "string"
                }
              }
              resources = [
                {
                  type = "Microsoft.Network/networkWatchers/flowLogs"
                  apiVersion = "2023-11-01"
                  name       = "[concat(parameters('resourceName'), '-NSG-Flow-Logs')]"
                  # name = "[concat('networkwatcher_', parameters('location'), '/Microsoft.Network', parameters('nsgRG'), parameters('resourceName'))]",
                  location = "[parameters('location')]"
                  # scope      = "[parameters('resourceId')]"
                  properties = {
                    enabled = true
                    storageId = "[parameters('storageAccountId')]"
                    targetResourceId = "[parameters('resourceId')]"
                    format = {
                      type = "JSON"
                      version = 1
                    }
                    retentionPolicy = {
                      days = 30
                      enabled = true
                    }
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
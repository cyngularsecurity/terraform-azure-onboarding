resource "azurerm_policy_definition" "nsg_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  policy_type  = "Custom"
  mode         = "All"

  name = format("cyngular-%s-%s-nsg-flow-logs-def", var.client_name, var.subscription_name)
  display_name = "Cyngular ${var.client_name} NSG Flow Logs - Apply flow logs on nsgs without, in sub ${var.subscription_name}"
  description  = "Ensures that NSG Flow Logs are configured to send logs to the specified storage account."
  management_group_id      = "/providers/Microsoft.Management/managementGroups/${data.azuread_client_config.current.tenant_id}"

  metadata = jsonencode({ category = "Network" })
  parameters = jsonencode({
    Effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "Enable or disable the execution of the policy"
      }
      allowedValues = ["Audit", "DeployIfNotExists", "Disabled"]
      defaultValue  = "DeployIfNotExists"
    }
    StorageAccountIds = {
      type = "Object"
      metadata = {
        displayName = "Storage Account Map"
        description = "A map of locations to storage account IDs where the logs should be sent."
      }
    }
    ClientLocations = {
      type = "Array"
      metadata = {
        displayName = "Allowed Locations"
        description = "The list of allowed locations for AKS clusters."
      }
    }
    networkWatcherRG = {
      type = "String" // Array
      metadata = {
        displayName = "Network Watcher resource group"
        description = "The Network Watcher regional instance is present in this resource group. The network security group flow logs resources are also created. This will be used only if a deployment is required. By default, it is named 'NetworkWatcherRG'."
        strongType = "existingResourceGroups"
      }
    }
    # networkWatcherName = {
    #   type = "Array" // Array
    #   metadata = {
    #     displayName = "Network Watcher name"
    #     description = "The name of the network watcher under which the flow log resources are created. Make sure it belongs to the same region as the network security group."
    #   }
    # }
    # retentionDays = {
    #   type = "String"
    #   metadata = {
    #     description = "The number of days for which flowlog data will be retained in storage account. If you want to retain data forever and do not want to apply any retention policy, set retention (days) to 0."
    #     displayName = "Number of days to retain flowlogs"
    #     defaultValue = "30"
    #   }
    # }
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
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
      effect = "[parameters('Effect')]",
      details = {
        roleDefinitionIds = [
          "/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa", // Monitoring Contributor
          "/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab"  // Storage Account Contributor
          # "/providers/microsoft.authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c" // Contributor
        ]
        type = "Microsoft.Network/networkWatchers/flowLogs"
        resourceGroupName = "[if(empty(coalesce(field('Microsoft.Network/networkSecurityGroups/flowLogs'))), parameters('networkWatcherRG'), split(first(field('Microsoft.Network/networkSecurityGroups/flowLogs[*].id')), '/')[4])]"
        name = "[if(empty(coalesce(field('Microsoft.Network/networkSecurityGroups/flowLogs[*].id'))), 'null/null', concat(split(first(field('Microsoft.Network/networkSecurityGroups/flowLogs[*].id')), '/')[8], '/', split(first(field('Microsoft.Network/networkSecurityGroups/flowLogs[*].id')), '/')[10]))]"
        # name = "[concat('Microsoft.Network/networkWatchers/', 'networkwatcher_', field('location'), '/flowLogs/', field('name'), '-NSG-Flow-Logs')]",
        # name = "[concat('networkwatcher_', field('location'), field('name'))]",
        existenceCondition = {
          allOf = [
            {
              field  = "Microsoft.Network/networkWatchers/flowLogs/targetResourceId",
              equals = "[concat(resourceGroup().id, '/providers/Microsoft.Network/networkSecurityGroups/', field('name'))]"
            },
            {
              field  = "Microsoft.Network/networkWatchers/flowLogs/enabled"
              equals = "true"
            },
            {
              field  = "Microsoft.Network/networkWatchers/flowLogs/storageId"
              # exists = true
              equals =  "[parameters('storageAccountIds')[field('location')]]"
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
              flowLogName = {
                value = "[if(empty(coalesce(field('Microsoft.Network/networkSecurityGroups/flowLogs'))), concat(take(concat(field('name'), '-', resourceGroup().name), 72), '-', 'flowlog'), split(first(field('Microsoft.Network/networkSecurityGroups/flowLogs[*].id')), '/')[10])]"
              }
              networkWatcherName = {
                value = "[if(empty(coalesce(field('Microsoft.Network/networkSecurityGroups/flowLogs'))), concat('NetworkWatcher_', field('location')), split(first(field('Microsoft.Network/networkSecurityGroups/flowLogs[*].id')), '/')[8])]"
                # value = "[if(empty(coalesce(field('Microsoft.Network/networkSecurityGroups/flowLogs'))), parameters('networkWatcherName'), split(first(field('Microsoft.Network/networkSecurityGroups/flowLogs[*].id')), '/')[8])]"
              }
              networkWatcherRG = {
              #   value = "[resourceGroup().name]"
                value = "[if(empty(coalesce(field('Microsoft.Network/networkSecurityGroups/flowLogs'))), parameters('networkWatcherRG'), split(first(field('Microsoft.Network/networkSecurityGroups/flowLogs[*].id')), '/')[4])]"
              }
            }
            template = {
              "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
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
                flowLogName = {
                  type = "string"
                }
              }
              resources = [
                {
                  # type       = "Microsoft.Resources/deployments"
                  # name = "[concat('flowlogDeployment-', uniqueString(parameters('flowlogName')))]"
                  # resourceGroup = "[parameters('networkWatcherRG')]"

                  type       = "Microsoft.Network/networkWatchers/flowLogs"
                  apiVersion = "2023-11-01"
                  # name       = "[concat(parameters('resourceName'), '-NSG-Flow-Logs')]"
                  name = "[concat(parameters('networkWatcherName'), '/', parameters('flowlogName'))]"
                  location   = "[parameters('location')]"
                  # scope      = "[parameters('resourceId')]"
                  properties = {
                    enabled          = true
                    storageId        = "[parameters('storageAccountId')]"
                    targetResourceId = "[parameters('resourceId')]"
                    format = {
                      type    = "JSON"
                      version = 2
                    }
                    retentionPolicy = {
                      days    = 30
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
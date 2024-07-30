resource "azurerm_policy_set_definition" "nsg_flow_logs_initiative" {
  count = var.enable_flow_logs ? 1 : 0

  policy_type = "Custom"
  name        = "Cyngular-NFL-Initiative"

  display_name        = "Cyngular ${var.client_name} NSG Flow Logs Initiative"
  description         = "Ensures that NSG Flow Logs are configured to send logs to the specified storage account."
  management_group_id = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.nsg_flow_logs[count.index].id
    parameter_values     = <<VALUE
    {
      "StorageAccountIds": {"value": "[parameters('StorageAccountIds')]"},
      "ClientLocations":   {"value": "[parameters('ClientLocations')]"},
      "NetworkWatcherRG":  {"value": "[parameters('NetworkWatcherRG')]"},
      "Effect":            {"value": "[parameters('Effect')]"}
    }
    VALUE
  }
  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.net_watcher[count.index].id
    parameter_values     = <<VALUE
    {
      "NetworkWatcherRG": {"value": "[parameters('NetworkWatcherRG')]"},
      "ClientLocations":   {"value": "[parameters('ClientLocations')]"},
      "Effect":            {"value": "[parameters('Effect')]"}
    }
    VALUE
  }

  parameters = jsonencode({
    ClientLocations = {
      type = "Array"
      metadata = {
        displayName = "Client Locations"
        description = "List of allowed locations"
      }
      # defaultValue = var.client_locations
    }
    StorageAccountIds = {
      type = "Object"
      metadata = {
        displayName = "Storage Account IDs"
        description = "Map of storage account IDs"
      }
      # defaultValue = merge(var.default_storage_accounts, { disabled = "empty" })
    }
    Effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "Enable or disable the execution of the policy"
      }
      allowedValues = ["Audit", "DeployIfNotExists", "Disabled"]
      # defaultValue  = "DeployIfNotExists"
    }
    NetworkWatcherRG = {
      type = "String"
      metadata = {
        displayName = "Network Watcher resource group"
        description = "The Network Watcher regional instance is present in this resource group. The network security group flow logs resources are also created. This will be used only if a deployment is required. By default, it is named 'NetworkWatcherRG'."
        # strongType  = "existingResourceGroups"
      }
      # allowedValues = ["NetworkWatcherRG"]
      # defaultValue  = "NetworkWatcherRG"
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
  metadata = jsonencode({
    category = "Cyngular - NSG Flow Logs"
    version  = "3.0.1"
  })
}

resource "azurerm_policy_definition" "nsg_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  policy_type = "Custom"
  mode        = "Indexed"

  name                = "Cyngular-NSG-fl-def"
  display_name        = "Cyngular ${var.client_name} NSG Flow Logs Definition"
  description         = "Ensures that NSG Flow Logs are configured to send logs to the specified storage account."
  management_group_id = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Network/networkSecurityGroups"
        },
        # {
        #   count = {
        #     field = "Microsoft.Network/networkSecurityGroups/flowLogs[*]"
        #   }
        #   equals = 0
        # },
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
          "${azurerm_role_definition.policy_assignment_def[0].role_definition_resource_id}",
          "/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7", // Network Contributor
          "/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab"  // Storage Account Contributor
        ],
        type              = "Microsoft.Network/networkWatchers/flowLogs"
        resourceGroupName = "[if(empty(coalesce(field('Microsoft.Network/networkSecurityGroups/flowLogs'))), parameters('NetworkWatcherRG'), split(first(field('Microsoft.Network/networkSecurityGroups/flowLogs[*].id')), '/')[4])]"
        name              = "[if(empty(coalesce(field('Microsoft.Network/networkSecurityGroups/flowLogs[*].id'))), 'null/null', concat(split(first(field('Microsoft.Network/networkSecurityGroups/flowLogs[*].id')), '/')[8], '/', split(first(field('Microsoft.Network/networkSecurityGroups/flowLogs[*].id')), '/')[10]))]"
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
              field = "Microsoft.Network/networkWatchers/flowLogs/storageId"
              # exists = true
              equals = "[parameters('storageAccountIds')[field('location')]]"
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
              NetworkWatcherRG = {
                #   value = "[resourceGroup().name]"
                value = "[if(empty(coalesce(field('Microsoft.Network/networkSecurityGroups/flowLogs'))), parameters('NetworkWatcherRG'), split(first(field('Microsoft.Network/networkSecurityGroups/flowLogs[*].id')), '/')[4])]"
              }
            }
            template = {
              "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
              contentVersion = "3.0.1.0"
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
                  # resourceGroup = "[parameters('NetworkWatcherRG')]"

                  type       = "Microsoft.Network/networkWatchers/flowLogs"
                  apiVersion = "2023-11-01"
                  # name       = "[concat(parameters('resourceName'), '-NSG-Flow-Logs')]"
                  name     = "[concat(parameters('networkWatcherName'), '/', parameters('flowlogName'))]"
                  location = "[parameters('location')]"
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
  metadata = jsonencode({
    category = "Cyngular - NSG Flow Logs"
    version  = "3.0.1"
  })
  parameters = jsonencode({
    Effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "Enable or disable the execution of the policy"
      }
      allowedValues = ["Audit", "DeployIfNotExists", "Disabled"]
      # defaultValue  = "DeployIfNotExists"
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
    NetworkWatcherRG = {
      type = "String"
      metadata = {
        displayName = "Network Watcher resource group"
        description = "The Network Watcher regional instance is present in this resource group. The network security group flow logs resources are also created. This will be used only if a deployment is required. By default, it is named 'NetworkWatcherRG'."
        # strongType  = "existingResourceGroups"
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
}

resource "azurerm_policy_definition" "net_watcher" {
  count = var.enable_flow_logs ? 1 : 0

  policy_type = "Custom"
  mode        = "Indexed"

  name                = "Cyngular-NSG-watcher-def"
  display_name        = "Cyngular ${var.client_name} Net Watcher Definition"
  description         = "Ensure Network Watcher is enabled in all specified locations"
  management_group_id = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"

  policy_rule = jsonencode({
    if = { // to determine where Network Watchers are needed.
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Network/virtualNetworks"
        },
        {
          field = "location"
          notIn = "[parameters('ClientLocations')]"
        }
      ]
    },
    then = {
      effect = "[parameters('Effect')]",
      details = {
        roleDefinitionIds = [
          "${azurerm_role_definition.policy_assignment_def[0].role_definition_resource_id}",
          "/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7", // Network Contributor
          "/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab"  // Storage Account Contributor
        ],
        type              = "Microsoft.Network/networkWatchers"
        resourceGroupName = "[parameters('NetworkWatcherRG')]"
        name              = "[concat('NetworkWatcher_', field('location'))]"
        # existenceCondition = {
        #   field  = "location",
        #   # equals = "[field('location')]"
        #   notIn    = "[parameters('ClientLocations')]"
        # },
        deployment = {
          properties = {
            mode = "incremental"
            parameters = {
              location = {
                value = "[field('location')]"
              }
              # resourceId = {
              #   value = "[field('id')]"
              # }
            }
            template = {
              "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
              contentVersion = "3.0.1.0"
              parameters = {
                # resourceId = {
                #   type = "string"
                # }
                location = {
                  type = "string"
                }
              }
              resources = [
                {
                  type       = "Microsoft.Network/networkWatchers"
                  apiVersion = "2023-11-01"
                  name       = "[concat('NetworkWatcher_', parameters('location'))]"
                  location   = "[parameters('location')]"
                  properties = {}
                }
              ]
            }
          }
        }
      }
    }
  })
  metadata = jsonencode({
    category = "Cyngular - NSG Flow Logs"
    version  = "3.0.1"
  })
  parameters = jsonencode({
    Effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "Enable or disable the execution of the policy"
      }
      allowedValues = ["Audit", "DeployIfNotExists", "Disabled"]
      # defaultValue  = "DeployIfNotExists"
    }
    NetworkWatcherRG = {
      type = "String"
      metadata = {
        displayName = "NetworkWatcher resource group name"
        description = "Name of the resource group where Network Watchers are located"
      }
      # allowedValues = ["NetworkWatcherRG"]
      # defaultValue  = "NetworkWatcherRG"
    }
    ClientLocations = {
      type = "Array"
      metadata = {
        displayName = "Allowed Locations"
        description = "The list of allowed locations for AKS clusters."
      }
    }
  })
}

# resource "azurerm_subscription_policy_assignment" "activity_logs_diagnostic_settings" {
#   for_each = var.enable_activity_logs ? var.subscription_names : {}

#   name         = format("cyngular-%s-%s-al", var.client_name, each.value)
#   display_name = "Cyngular ${var.client_name} Activity Logs - Assigned to sub - ${each.value}"
#   description  = "Logging Activity Logs with diagnostic settings for sub - ${each.value}"

#   policy_definition_id = azurerm_policy_definition.activity_logs_diagnostic_settings[0].id
#   subscription_id      = "/subscriptions/${var.subscription_ids[each.key]}"
#   location = var.main_location
#   identity {
#     type         = "UserAssigned"
#     identity_ids = [azurerm_user_assigned_identity.policy_assignment_identity[each.key].id]
#   }

#   parameters = jsonencode({
#     StorageAccountID = {
#       value = var.default_storage_accounts[var.main_location]
#     }
#   })
# }

# resource "azurerm_subscription_policy_assignment" "nsg_flow_logs" {
#   count = var.enable_flow_logs ? 1 : 0

#   name         = format("cyngular-%s-%s-nsg-flow-logs", var.client_name, var.subscription_name)
#   display_name = "Cyngular ${var.client_name} NSG Flow Logs - Apply flow logs on nsgs without"
#   description  = "Ensures that NSG Flow Logs are configured to send logs to the specified storage account."

#   # policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/62329546-775b-4a3d-a4cb-eb4bb990d2c0"
#   policy_definition_id = azurerm_policy_definition.nsg_flow_logs[count.index].id
#   subscription_id      = "/subscriptions/${var.subscription_id}"
#   location             = var.main_location
#   identity {
#     type         = "UserAssigned"
#     identity_ids = [azurerm_user_assigned_identity.policy_assignment_identity[count.index].id]
#   }

#   parameters = jsonencode({
#     StorageAccountIds = {
#       value = merge(var.default_storage_accounts, { disabled = "empty" })
#     }
#     ClientLocations = {
#       value = var.client_locations
#     }
#     Effect = {
#       value = "DeployIfNotExists" // Disabled // DeployIfNotExists
#     }
#     networkWatcherRG = {
#       value = "NetworkWatcherRG"
#     }
#   })

#   # non_compliance_message {
#   #   content = "policy - cyngular - nsg flow logs - this resource is non compliant"
#   # }

#   resource_selectors {
#     name = "NSGsInAllowedLocations"
#     selectors {
#       kind = "resourceLocation"
#       in   = var.client_locations
#     }
#     # selectors {
#     #   kind = "resourceType"
#     #   in   = ["Microsoft.Network/networkSecurityGroups"]
#     # }
#   }
#   # not_scopes = [
#   # ]
# }

# resource "azurerm_subscription_policy_assignment" "aks_diagnostic_settings" {
#   for_each = var.enable_aks_logs ? var.subscription_names : {}

#   name         = format("cyngular-%s-%s-aks", var.client_name, each.value)
#   display_name = "Cyngular ${var.client_name} AKS - Assigned to sub - ${each.value}"
#   description  = "Logging EKS Clusters for sub - ${each.value}"

#   policy_definition_id = azurerm_policy_definition.aks_diagnostic_settings[0].id
#   subscription_id      = "/subscriptions/${var.subscription_ids[each.key]}"
#   location = var.main_location
#   identity {
#     type         = "UserAssigned"
#     identity_ids = [azurerm_user_assigned_identity.policy_assignment_identity[0].id]
#   }

#   parameters = jsonencode({
#     StorageAccountIds = {
#       value = merge(var.default_storage_accounts, { disabled = "empty" })
#     }
#     ClientLocations = {
#       value = var.client_locations
#     }
#   })

#   # non_compliance_message {
#   #   content = "policy - cyngular - aks - this resource is non compliant"
#   # }

#   # resource_selectors {
#   #   name = "AKSClustersInAllowedLocations"
#   #   selectors {
#   #     kind = "resourceLocation" // resourceWithoutLocation
#   #     in   = var.client_locations
#   #   }
#   #   # selectors {
#   #   #   kind = "resourceType"
#   #   #   in   = ["Microsoft.ContainerService/managedClusters"]
#   #   # }
#   # }
# }

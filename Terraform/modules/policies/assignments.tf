
resource "azurerm_subscription_policy_assignment" "aks_diagnostic_settings" {
  for_each = toset(var.subscriptions)

  name                 = "require-aks-diagnostic-settings-assignment"
  display_name = "Cyngular ${var.client_name} Require Diagnostic Settings for AKS Clusters"
  description          = "Ensures that resources have diagnostic settings configured to write logs to the specified storage account."

  policy_definition_id = azurerm_policy_definition.aks_diagnostic_settings.id
  subscription_id = "/subscriptions/${each.value}"

  location        = var.main_location
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.policy_assignment.id]
  }

  parameters = jsonencode({
    storageAccountIds = {
      value = var.default_storage_accounts
      // {
      #   for location, sa in var.default_storage_accounts : location => sa
      # }
    }
    allowedLocations = {
      value = var.client_locations
    }
  })
}

# resource "azurerm_subscription_policy_assignment" "activity_logs_diagnostic_settings" {
#   for_each = var.subscriptions

#   name                 = "assign-diagnostic-settings-policy"
#   policy_definition_id = azurerm_policy_definition.activity_logs_diagnostic_settings.id
#   display_name         = "Assign Activity Logs Diagnostic Settings Policy"
#   description          = "Ensures that resources have diagnostic settings configured to write logs to the specified storage account."

  # subscription_id = "/subscriptions/${.value}"
#   location        = var.main_location
#   identity {
#     type         = "UserAssigned"
#     identity_ids = [azurerm_user_assigned_identity.policy_assignment.id]
#   }

  # parameters = jsonencode({
  #   subscription = {
  #     value = each.value
  #   }
  #   storageAccountIds = {
  #     value = values(var.default_storage_accounts)
  #   }
  #   allowedLocations = {
  #     value = var.client_locations
  #   }
#     location = {
#       value = var.main_location
#     }
  # })

# resource "azurerm_subscription_policy_assignment" "audit_event_diagnostic_settings" {
#   for_each = var.subscriptions

#   name                 = "assign-diagnostic-settings-policy"
#   policy_definition_id = azurerm_policy_definition.audit_event_diagnostic_settings.id
#   display_name         = "Assign Audit Event Diagnostic Settings Policy"
#   description          = "Ensures that resources have diagnostic settings configured to write logs to the specified storage account."

#   subscription_id      = each.value
#   location = var.main_location
#   identity {
#     type = "UserAssigned"
#     identity_ids = [azurerm_user_assigned_identity.policy_assignment.id]
#   }

#   parameters = jsonencode({
#     location = {
#       value = var.main_location
#     }
#     storageAccountID = {
#       value = var.storage_acocount_id
#     }
#     resourceTypes = {
#       value = [
#         "Microsoft.KeyVault/vaults",
#         "Microsoft.ContainerService/managedClusters",
#         "Microsoft.Network/networkSecurityGroups"
#       ]
#     }
#   })
# }


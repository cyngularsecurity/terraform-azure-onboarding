resource "azurerm_subscription_policy_assignment" "audit_event_diagnostic_settings" {
  name                 = "assign-diagnostic-settings-policy"
  policy_definition_id = azurerm_policy_definition.diagnostic_settings_policy.id
  display_name         = "Assign Diagnostic Settings Policy"
  subscription_id      = var.subscription
  location = var.main_location
  description          = "Ensures that resources have diagnostic settings configured to write logs to the specified storage account."

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.policy_assignment.id]
  }

  parameters = jsonencode({
    location = {
      value = var.main_location  # Specify the location for the storage account
    }
    storageAccountID = {
      value = var.storage_acocount_id
    }
    resourceTypes = {
      value = [
        "Microsoft.KeyVault/vaults",
        "Microsoft.ContainerService/managedClusters",
        "Microsoft.Network/networkSecurityGroups"
      ]
    }
  })
}

# resource "azurerm_subscription_policy_assignment" "diagnostic_settings_assignment" {
#   name                 = "enforce-diagnostic-settings"
#   scope                = "/subscriptions/${var.subscription_id}"
#   policy_definition_id = azurerm_policy_definition.diagnostic_settings_policy.id

#   display_name = "Apply diagnostic settings to all resources"
#   description  = "Ensure that diagnostic settings are applied to all resources in the subscription."

#   parameters = <<PARAMETERS
#   {
#     "storageAccountId": {
#       "value": "${var.storage_account_id}"
#     }
#     "categories": {
#       "value": ${jsonencode(var.log_categories)}
#     }
#   }
#   PARAMETERS
# }

# resource "azurerm_subscription_policy_assignment" "aks_diagnostic_settings" {
#   name                 = "require-aks-diagnostic-settings-assignment"
#   policy_definition_id = azurerm_policy_definition.aks_diagnostic_settings_policy.id
#   subscription_id      = "/subscriptions/${var.subscription}"

#   display_name         = "Require Diagnostic Settings for AKS Clusters"

  # parameters = jsonencode({
  #   storageAccountIds = {
  #     value = values(var.location_storage_account_map)
  #   }
  # })
# }



resource "azurerm_subscription_policy_assignment" "aks_diagnostic_settings" {
  count        = var.enable_aks_logs ? 1 : 0
  name         = "cyngular-${var.client_name}-aks-assignment"
  display_name = "Cyngular ${var.client_name} AKS Require Diagnostic Settings for Clusters"
  description  = "Ensures that resources have diagnostic settings configured to write logs to the specified storage account."

  # policy_definition_id = azurerm_policy_definition.aks_diagnostic_settings.id
  policy_definition_id = azurerm_policy_definition.aks_diagnostic_settings[count.index].id
│     
  subscription_id      = "/subscriptions/${var.subscription}"

  location = var.main_location
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.policy_assignment_identity.id]
  }
  parameters = jsonencode({
    StorageAccountIds = {
      value = merge(var.default_storage_accounts, { disabled = "empty" })
    }
    # StorageAccountIds = {
    #   value = var.default_storage_accounts
    # }
    ClientLocations = {
      value = var.client_locations
    }
  })
}

resource "azurerm_subscription_policy_assignment" "activity_logs_diagnostic_settings" {
  count                = var.enable_activity_logs ? 1 : 0
  name                 = "cyngular-${var.client_name}-activity-logs-assignment"
  policy_definition_id = azurerm_policy_definition.activity_logs_diagnostic_settings[count.index].id
  display_name         = "Cyngular ${var.client_name} Activity Logs - Assign Diagnostic Settings On Sub"
  description          = "Ensures that resources have diagnostic settings configured to write logs to the specified storage account."

  subscription_id = "/subscriptions/${var.subscription}"
  location        = var.main_location
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.policy_assignment_identity[count.index].id]
  }

  parameters = jsonencode({
    subscription = {
      value = var.subscription
    }
    StorageAccountID = {
      value = var.default_storage_accounts[var.main_location]
    }
  })
}

resource "azurerm_subscription_policy_assignment" "audit_event_diagnostic_settings" {
  count = var.enable_audit_events_logs ? 1 : 0

  name                 = "cyngular-audir-event-diagnostic-settings-assignment"
  policy_definition_id = azurerm_policy_definition.audit_event_diagnostic_settings.id
  display_name         = "Assign Audit Event Diagnostic Settings Policy"
  description          = "Ensures that resources have diagnostic settings configured to write logs to the specified storage account."

  subscription_id = var.subscription
  location        = var.main_location
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.policy_assignment_identity.id]
  }

  parameters = jsonencode({
    StorageAccountIds = {
      value = merge(var.default_storage_accounts, { disabled = "empty" })
    }
    ClientLocations = {
      value = var.client_locations
    }
    ResourceTypes = {
      value = [
        "Microsoft.KeyVault/vaults",
        "Microsoft.ContainerService/managedClusters",
        "Microsoft.Network/networkSecurityGroups"
      ]
    }
  })
}


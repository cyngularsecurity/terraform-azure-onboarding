
resource "azurerm_subscription_policy_assignment" "aks_diagnostic_settings" {
  count        = var.enable_aks_logs ? 1 : 0

  name         = "cyngular-${var.client_name}-aks-assignment"
  display_name = "Cyngular ${var.client_name} AKS Require Diagnostic Settings for Clusters"
  description  = "Ensures that resources have diagnostic settings configured to write logs to the specified storage account."

  policy_definition_id = azurerm_policy_definition.aks_diagnostic_settings[count.index].id
  subscription_id      = "/subscriptions/${var.subscription}"

  location = var.main_location
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.policy_assignment_identity[count.index].id]
  }

  parameters = jsonencode({
    StorageAccountIds = {
      value = merge(var.default_storage_accounts, { disabled = "empty" })
    }
    ClientLocations = {
      value = var.client_locations
    }
  })

  non_compliance_message {
    content = "policy - cyngular - aks - this resource is non compliant"
  }

  resource_selectors {
    name = "AKSClustersInAllowedLocations"
    selectors {
      kind = "resourceLocation" // resourceWithoutLocation
      in   = var.client_locations
    }
    selectors {
      kind = "resourceType"
      in   = ["Microsoft.ContainerService/managedClusters"]
    }
  }
}

resource "azurerm_subscription_policy_assignment" "activity_logs_diagnostic_settings" {
  count                = var.enable_activity_logs ? 1 : 0

  name                 = "cyngular-${var.client_name}-activity-logs-assignment"
  display_name         = "Cyngular ${var.client_name} Activity Logs - Assign Diagnostic Settings On Sub"
  description          = "Ensures that resources have diagnostic settings configured to write logs to the specified storage account."

  policy_definition_id = azurerm_policy_definition.activity_logs_diagnostic_settings[count.index].id
  subscription_id = "/subscriptions/${var.subscription}"
  location        = var.main_location
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.policy_assignment_identity[count.index].id]
  }

  parameters = jsonencode({
    StorageAccountID = {
      value = var.default_storage_accounts[var.main_location]
    }
  })
}

resource "azurerm_subscription_policy_assignment" "nsg_flow_logs" {
  count        = var.enable_flow_logs ? 1 : 0

  name         = "cyngular-${var.client_name}-nsg-flow-logs-assignment"
  display_name = "Cyngular ${var.client_name} NSG Flow Logs - Apply flow logs on nsgs without"
  description  = "Ensures that NSG Flow Logs are configured to send logs to the specified storage account."

  # policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/62329546-775b-4a3d-a4cb-eb4bb990d2c0"
  policy_definition_id = azurerm_policy_definition.nsg_flow_logs[count.index].id
  subscription_id      = "/subscriptions/${var.subscription}"

  location = var.main_location
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.policy_assignment_identity[count.index].id]
  }

  parameters = jsonencode({
    StorageAccountIds = {
      value = merge(var.default_storage_accounts, { disabled = "empty" })
    }
    ClientLocations = {
      value = var.client_locations
    }
    Effect = {
      value = "DeployIfNotExists"
    }
  })

  non_compliance_message {
    content = "policy - cyngular - nsg flow logs - this resource is non compliant"
  }

  resource_selectors {
    name = "NSGsInAllowedLocations"
    selectors {
      kind = "resourceLocation"
      in   = var.client_locations
    }
    selectors {
      kind = "resourceType"
      in   = ["Microsoft.Network/networkSecurityGroups"]
    }
  }

  # not_scopes = [

  # ]
}

# resource "azurerm_subscription_policy_assignment" "audit_event_diagnostic_settings" {
#   count = var.enable_audit_events_logs ? 1 : 0

#   name         = "cyngular-${var.client_name}-audit-event-diagnostic-settings-assignment"
#   display_name = "Cyngular ${var.client_name} Assign Audit Event Diagnostic Settings Policy"
#   description          = "Ensures that resources have diagnostic settings configured to write logs to the specified storage account."

#   policy_definition_id = azurerm_policy_definition.audit_event_diagnostic_settings[count.index].id
#   subscription_id = "/subscriptions/${var.subscription}"
#   location        = var.main_location
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
#     # ResourceTypes = {
#     #   value = [
#     #     "Microsoft.KeyVault/vaults",
#     #     "Microsoft.Network/networkSecurityGroups",
#     #   ]
#     # }
#     blacklistedResourceTypes = {
#       value = var.client_locations
#     }
#     resourceTypesGroup1 = {
#       value = var.client_locations
#     }
#     resourceTypesGroup2 = {
#       value = var.client_locations
#     }
#     resourceTypesGroup2 = {
#       value = var.client_locations
#     }
#     resourceTypesGroup2 = {
#       value = var.client_locations
#     }
#   })
#   resource_selectors {
#     name = "ResourcesInAllowedLocations"
#     selectors {
#       kind = "resourceLocation"
#       in   = var.client_locations
#     }
#   }
# }


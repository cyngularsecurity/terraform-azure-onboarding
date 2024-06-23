
locals {
  # max_length           = 24
  # base_name            = "cyngular-activity-logs-mgmt"
  # max_length_base      = local.max_length - length(local.base_name) - 2 # Subtract base length and two dashes
  # short_client_name     = substr(var.client_name, 0, local.max_length_base / 2)
  # truncated_subscription = substr(var.subscription_name, 0, local.max_length_base / 2)
  # sure_name       = format("cyngular-%s-%s-activity-logs-mgmt", local.truncated_client, local.truncated_subscription)

  short_client_name = substr(var.client_name, 0, floor(9 / 2))
  short_sub_name = substr(var.subscription_name, 0, 9 - length(local.short_client_name))
}

resource "azurerm_management_group_policy_assignment" "activity_logs_diagnostic_settings" {
  count = var.enable_activity_logs ? 1 : 0

  name         = format("cyngular-%s-%s-mgmt", local.short_client_name, local.short_sub_name)
  # name         = format("cyngular-%s-%s-mgmt", var.client_name, var.subscription_name)
  # name         = local.sure_name
  display_name = "Cyngular ${var.client_name} Activity Logs - Assign Diagnostic Settings On Sub ${var.subscription_name}"
  description  = "Ensures that resources have diagnostic settings configured to write logs to the specified storage account."

  policy_definition_id = azurerm_policy_definition.activity_logs_diagnostic_settings[count.index].id
  management_group_id      = "/providers/Microsoft.Management/managementGroups/${data.azuread_client_config.current.tenant_id}"
  location             = var.main_location
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.policy_assignment_identity[count.index].id]
  }

  parameters = jsonencode({
    StorageAccountID = {
      value = var.default_storage_accounts[var.main_location]
    }
    # MainLocation = {
    #   value = var.main_location
    # }
  })
}


# resource "azurerm_subscription_policy_assignment" "activity_logs_diagnostic_settings" {
#   count = var.enable_activity_logs ? 1 : 0

#   name         = format("cyngular-%s-%s-activity-logs", var.client_name, var.subscription_name)
#   display_name = "Cyngular ${var.client_name} Activity Logs - Assign Diagnostic Settings On Sub ${var.subscription_name}"
#   description  = "Ensures that resources have diagnostic settings configured to write logs to the specified storage account."

#   policy_definition_id = azurerm_policy_definition.activity_logs_diagnostic_settings[count.index].id
#   subscription_id      = "/subscriptions/${var.subscription_id}"
#   location             = var.main_location
#   identity {
#     type         = "UserAssigned"
#     identity_ids = [azurerm_user_assigned_identity.policy_assignment_identity[count.index].id]
#   }

#   parameters = jsonencode({
#     StorageAccountID = {
#       value = var.default_storage_accounts[var.main_location]
#     }
#     # MainLocation = {
#     #   value = var.main_location
#     # }
#   })

#   # resource_selectors {
#   #   name = "Subscriptions"
#   #   selectors {
#   #     kind = "resourceType"
#   #     in   = ["Microsoft.Resources/subscriptions"]
#   #   }
#   # }
# }

resource "azurerm_subscription_policy_assignment" "audit_event_diagnostic_settings" {
  count = var.enable_audit_events_logs ? 1 : 0

  name         = format("cyngular-%s-%s-audit-event", var.client_name, var.subscription_name)
  display_name = "Cyngular ${var.client_name} Audit Event - Diagnostic Settings Policy"
  description          = "Ensures that resources have diagnostic settings configured to write logs to the specified storage account."

  policy_definition_id = azurerm_policy_definition.audit_event_diagnostic_settings[count.index].id
  subscription_id = "/subscriptions/${var.subscription_id}"
  location        = var.main_location
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
    blacklistedTypes = {
      value = [local.resource_types.black_listed]
    }
    typeListA = {
      value = [local.resource_types.list_a]
    }
    typeListB = {
      value = [local.resource_types.list_b]
    }
  })
  # resource_selectors {
  #   name = "ResourcesInAllowedLocations"
  #   selectors {
  #     kind = "resourceLocation"
  #     in   = var.client_locations
  #   }
  # }
}

resource "azurerm_subscription_policy_assignment" "nsg_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name         = format("cyngular-%s-%s-nsg-flow-logs", var.client_name, var.subscription_name)
  display_name = "Cyngular ${var.client_name} NSG Flow Logs - Apply flow logs on nsgs without"
  description  = "Ensures that NSG Flow Logs are configured to send logs to the specified storage account."

  # policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/62329546-775b-4a3d-a4cb-eb4bb990d2c0"
  policy_definition_id = azurerm_policy_definition.nsg_flow_logs[count.index].id
  subscription_id      = "/subscriptions/${var.subscription_id}"
  location             = var.main_location
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
      value = "DeployIfNotExists" // Disabled // DeployIfNotExists
    }
    networkWatcherRG = {
      value = "NetworkWatcherRG"
    }
  })

  # non_compliance_message {
  #   content = "policy - cyngular - nsg flow logs - this resource is non compliant"
  # }

  resource_selectors {
    name = "NSGsInAllowedLocations"
    selectors {
      kind = "resourceLocation"
      in   = var.client_locations
    }
    # selectors {
    #   kind = "resourceType"
    #   in   = ["Microsoft.Network/networkSecurityGroups"]
    # }
  }
  # not_scopes = [
  # ]
}

resource "azurerm_subscription_policy_assignment" "aks_diagnostic_settings" {
  count = var.enable_aks_logs ? 1 : 0

  name         = format("cyngular-%s-%s-aks", var.client_name, var.subscription_name)
  display_name = "Cyngular ${var.client_name} AKS - Assigned to sub - ${var.subscription_name}"
  # description  = "Logging EKS Clusters for sub - ${var.subscription_name}"

  policy_definition_id = azurerm_policy_definition.aks_diagnostic_settings[count.index].id
  subscription_id      = "/subscriptions/${var.subscription_id}"
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

  # non_compliance_message {
  #   content = "policy - cyngular - aks - this resource is non compliant"
  # }

  # resource_selectors {
  #   name = "AKSClustersInAllowedLocations"
  #   selectors {
  #     kind = "resourceLocation" // resourceWithoutLocation
  #     in   = var.client_locations
  #   }
  #   # selectors {
  #   #   kind = "resourceType"
  #   #   in   = ["Microsoft.ContainerService/managedClusters"]
  #   # }
  # }
}

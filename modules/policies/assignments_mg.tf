
resource "azurerm_management_group_policy_assignment" "activity_logs" {
  count = var.enable_activity_logs ? 1 : 0

  # name         = format("cyngular-%s-audit-logs-mgmt", var.client_name)
  name         = "cyngular-al-${var.client_name}"
  display_name = "Cyngular ${var.client_name} Activity Logs - Assign Diagnostic Settings"
  description  = "Ensures that resources have diagnostic settings configured to write logs to the specified storage account."

  policy_definition_id = azurerm_policy_definition.activity_logs[count.index].id
  management_group_id  = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"
  location             = var.main_location
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.policy_assignment_identity[count.index].id]
  }

  non_compliance_message {
    content = "Cyngular Policy - activity logs - this resource is non compliant, please apply remediation"
  }

  parameters = jsonencode({
    StorageAccountID = {
      value = var.default_storage_accounts[var.main_location]
    }
  })
}

resource "azurerm_management_group_policy_assignment" "audit_event" {
  count = var.enable_audit_events_logs ? 1 : 0

  name         = "cyngular-ae-${var.client_name}"
  display_name = "Cyngular ${var.client_name} Audit Event - Assign Diagnostic Settings"
  description  = "Ensures that resources have diagnostic settings configured to write logs to the specified storage account."

  # policy_definition_id = azurerm_policy_definition.audit_event[count.index].id
  policy_definition_id = azurerm_policy_set_definition.audit_event_initiative[count.index].id

  management_group_id = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"
  location            = var.main_location
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.policy_assignment_identity[count.index].id]
  }

  resource_selectors {
    name = "ResourcesInAllowedLocations"
    selectors {
      kind = "resourceLocation"
      in   = var.client_locations
    }
    selectors {
      kind   = "resourceType"
      not_in = local.resource_types.black_listed
    }
  }

  parameters = jsonencode({
    StorageAccountIds = {
      value = merge(var.default_storage_accounts, { disabled = "empty" })
    }
    ClientLocations = {
      value = var.client_locations
    }
    typeListA = {
      value = local.resource_types.list_a
    }
    typeListB = {
      value = local.resource_types.list_b
    }
  })
}

resource "azurerm_management_group_policy_assignment" "nsg_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name         = "cyngular-nfl-mgmt"
  display_name = "Cyngular ${var.client_name} NSG Flow Logs - Apply flow logs on nsgs without"
  description  = "Ensures that NSG Flow Logs are configured to send logs to the specified storage account."


  policy_definition_id = azurerm_policy_set_definition.nsg_flow_logs_initiative[count.index].id
  # policy_definition_id = azurerm_policy_definition.nsg_flow_logs[count.index].id
  management_group_id = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"
  location            = var.main_location
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
    NetworkWatcherRG = {
      value = "NetworkWatcherRG"
    }
  })

  non_compliance_message {
    content = "policy - cyngular - nsg flow logs - this resource is non compliant, apply remediation"
  }
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

resource "azurerm_management_group_policy_assignment" "aks_diagnostic_settings" {
  count = var.enable_aks_logs ? 1 : 0

  name         = "cyngular-aks-mgmt"
  display_name = "Cyngular ${var.client_name} AKS Diagnostic Settigns Enforce"
  description  = "Logging EKS Clusters to same location storage accounts"

  policy_definition_id = azurerm_policy_definition.aks_diagnostic_settings[count.index].id
  management_group_id  = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"
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
  })

  # non_compliance_message {
  #   content = "policy - cyngular - nsg flow logs - this resource is non compliant"
  # }
  resource_selectors {
    name = "AKSClustersInAllowedLocations"
    selectors {
      kind = "resourceLocation" // resourceWithoutLocation
      in   = var.client_locations
    }
    # selectors {
    #   kind = "resourceType"
    #   in   = ["Microsoft.ContainerService/managedClusters"]
    # }
  }
}
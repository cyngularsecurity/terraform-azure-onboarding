resource "azurerm_user_assigned_identity" "policy_assignment_identity" {
  count = local.logging_enabled ? 1 : 0
  name  = format("%s-policy-def-uai-mgmt", var.client_name)

  location            = var.main_location
  resource_group_name = var.cyngular_rg_name
}

resource "azurerm_role_definition" "policy_assignment_def" {
  # for_each = local.logging_enabled ? var.subscription_names : {}
  count = local.logging_enabled ? 1 : 0

  # scope      = "/subscriptions/${var.subscription_ids[each.key]}"
  scope = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"

  name        = format("%s-policies-cyngular-role-mgmt", var.client_name)
  description = "cyngular main role for policy def & assignments"

  permissions {
    actions = [
      "Microsoft.ManagedIdentity/userAssignedIdentities/assign/action",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/subscriptions/read",
      "Microsoft.Authorization/*/read",

      "Microsoft.Authorization/roleAssignments/write",
      "Microsoft.Management/managementGroups/read",
      # "Microsoft.Authorization/roleAssignments/*",

      "Microsoft.Authorization/policyDefinitions/*",
      "Microsoft.Authorization/policyAssignments/*",
      # "Microsoft.Authorization/policySetDefinitions/*",

      "Microsoft.ContainerService/managedClusters/read",
      "Microsoft.Resources/deployments/*",

      "Microsoft.Storage/storageAccounts/listkeys/action",
      "Microsoft.Storage/storageAccounts/write",
      "Microsoft.Storage/storageAccounts/blobServices/containers/write",

      "Microsoft.Insights/diagnosticSettings/read",
      "Microsoft.Insights/diagnosticSettings/write",

      "Microsoft.Network/networkWatchers/flowLogs/write",
      "Microsoft.Network/networkSecurityGroups/write",
    ]
  }

  assignable_scopes = concat(
    [for sub in var.subscription_ids : "/subscriptions/${sub}"],
    ["/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"]
  )
}

# resource "azurerm_role_assignment" "policy_assigment_custom_subs" {
#   for_each = local.logging_enabled ? var.subscription_names : {}
#   scope    = "/subscriptions/${var.subscription_ids[each.key]}"

#   principal_id       = azurerm_user_assigned_identity.policy_assignment_identity[0].principal_id
#   role_definition_id = azurerm_role_definition.policy_assignment_def[0].role_definition_resource_id
#   # skip_service_principal_aad_check = true
#   lifecycle {
#     ignore_changes = [
#       role_definition_id
#     ]
#   }
# }

resource "azurerm_role_assignment" "policy_assigment_custom_mgmt" {
  count = var.enable_aks_logs || var.enable_flow_logs || var.enable_activity_logs || var.enable_audit_events_logs ? 1 : 0
  scope = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"

  principal_id       = azurerm_user_assigned_identity.policy_assignment_identity[count.index].principal_id
  role_definition_id = azurerm_role_definition.policy_assignment_def[count.index].role_definition_resource_id
}

# resource "azurerm_role_assignment" "policy_assigment_reader" {
#   for_each = var.enable_aks_logs || var.enable_flow_logs || var.enable_activity_logs || var.enable_audit_events_logs ? var.subscription_names : {}
#   scope = "/subscriptions/${var.subscription_ids[each.key]}"

#   principal_id = azurerm_user_assigned_identity.policy_assignment_identity[0].principal_id
#   role_definition_name = "Reader" // "Management Group Reader" // "Subscription Reader" // "User Access Administrator"
# }

# resource "azurerm_role_assignment" "policy_assigment_monitor_contributor" {
#   for_each = var.enable_aks_logs || var.enable_flow_logs || var.enable_activity_logs || var.enable_audit_events_logs ? var.subscription_names : {}
#   scope = "/subscriptions/${var.subscription_ids[each.key]}

#   principal_id = azurerm_user_assigned_identity.policy_assignment_identity[each.key].id
#   role_definition_name = "Monitoring Contributor"
# }
# resource "azurerm_role_assignment" "policy_assigment_sa_contributor" {
#   for_each = var.enable_aks_logs || var.enable_flow_logs || var.enable_activity_logs || var.enable_audit_events_logs ? var.subscription_names : {}
#   scope = "/subscriptions/${var.subscription_ids[each.key]}"

#   principal_id = azurerm_user_assigned_identity.policy_assignment_identity[each.key].id
#   role_definition_name = "Storage Account Contributor"
# }
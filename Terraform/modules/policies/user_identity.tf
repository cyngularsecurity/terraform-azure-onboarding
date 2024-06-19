resource "azurerm_user_assigned_identity" "policy_assignment_identity" {
  count                = var.enable_aks_logs || var.enable_flow_logs || var.enable_activity_logs || var.enable_audit_events_logs ? 1 : 0
# cancel ^ if should enable activity logs by default, for assignemnt also, in refs
  name = format("%s-policy-def", var.client_name)

  location            = var.main_location
  resource_group_name = var.cyngular_rg_name
}

resource "azurerm_role_definition" "policy_assignment" {
  count                = var.enable_aks_logs || var.enable_flow_logs || var.enable_activity_logs || var.enable_audit_events_logs ? 1 : 0
  name        = format("%s-policy-def", var.client_name)
  scope       = "/subscriptions/${var.subscription}"
  description = "cyngular main"

  permissions {
    actions = [
      "Microsoft.ManagedIdentity/userAssignedIdentities/assign/action",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/subscriptions/read",
      "Microsoft.Authorization/policyAssignments/*",

      "Microsoft.Storage/storageAccounts/write",
      "Microsoft.Storage/storageAccounts/blobServices/containers/write",
      "Microsoft.Storage/storageAccounts/listkeys/action",

      "Microsoft.Insights/diagnosticSettings/*",
      # "Microsoft.Insights/diagnosticSettings/delete",

      "Microsoft.ContainerService/managedClusters/read",
      "Microsoft.Resources/deployments/*",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/subscriptions/resourceGroups/deployments/*",
    ]
    not_actions = []
  }

  assignable_scopes = [
    "/subscriptions/${var.subscription}",
  ]
}

resource "azurerm_role_assignment" "policy_assigment_main_custom" {
  count                = var.enable_aks_logs || var.enable_flow_logs || var.enable_activity_logs || var.enable_audit_events_logs ? 1 : 0
  scope = "/subscriptions/${var.subscription}"

  principal_id       = azurerm_user_assigned_identity.policy_assignment_identity[count.index].principal_id 
  role_definition_id = azurerm_role_definition.policy_assignment[count.index].role_definition_resource_id
}

# resource "azurerm_role_assignment" "policy_assigment_monitor_contributor" {
#   scope        =  "/subscriptions/${var.subscription}"

#   principal_id = azurerm_user_assigned_identity.policy_assignment_identity[count.index].id
#   role_definition_name = "Monitoring Contributor"
# }

# resource "azurerm_role_assignment" "policy_assigment_sa_contributor" {
#   principal_id = azurerm_user_assigned_identity.policy_assignment_identity[count.index].id
#   scope        =  "/subscriptions/${var.subscription}"

#   role_definition_name = "Storage Account Contributor"
# }

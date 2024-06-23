resource "azurerm_user_assigned_identity" "policy_assignment_identity" {
  count = var.enable_aks_logs || var.enable_flow_logs || var.enable_activity_logs || var.enable_audit_events_logs ? 1 : 0
  name = format("%s-%s-policy-def-uai", var.client_name, var.subscription_name)

  location            = var.main_location
  resource_group_name = var.cyngular_rg_name
}

resource "azurerm_role_definition" "policy_assignment" {
  count       = var.enable_aks_logs || var.enable_flow_logs || var.enable_activity_logs || var.enable_audit_events_logs ? 1 : 0
  name        = format("%s-%s-policy-def-cyngular-role", var.client_name, var.subscription_name)
  scope       = "/subscriptions/${var.subscription_id}"
  description = "cyngular main"

  permissions {
    actions = [
      "Microsoft.ManagedIdentity/userAssignedIdentities/assign/action",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/subscriptions/read",
      "Microsoft.Authorization/policyAssignments/*",

      "Microsoft.ContainerService/managedClusters/read",
      "Microsoft.Resources/deployments/*",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      # "Microsoft.Resources/subscriptions/resourceGroups/deployments/*",
      # "providers/Microsoft.Management/managementGroups/write",

      "Microsoft.Storage/storageAccounts/listkeys/action",
      "Microsoft.Storage/storageAccounts/write",
      "Microsoft.Storage/storageAccounts/blobServices/containers/write",

      "Microsoft.Insights/diagnosticSettings/read",
      "Microsoft.Insights/diagnosticSettings/write",

      "Microsoft.Network/networkWatchers/flowLogs/write",
      "Microsoft.Network/networkSecurityGroups/write",
    ]
  }

  assignable_scopes = [
    "/subscriptions/${var.subscription_id}",
    # "/providers/Microsoft.Management/managementGroups/${data.azuread_client_config.current.tenant_id}",
  ]
}

resource "azurerm_role_assignment" "policy_assigment_main_custom" {
  count = var.enable_aks_logs || var.enable_flow_logs || var.enable_activity_logs || var.enable_audit_events_logs ? 1 : 0
  scope = "/subscriptions/${var.subscription_id}"

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
resource "azurerm_user_assigned_identity" "policy_assignment" {
  name = format("%s-policy-def", var.client_name)

  location            = var.main_location
  resource_group_name = var.cyngular_rg_name
}

resource "azurerm_role_definition" "policy_assignment" {
  name        = format("%s-image-builder", var.client_name)
  scope       = local.main_sub
  description = "cyngular main"

  permissions {
    actions = [
      "Microsoft.ManagedIdentity/userAssignedIdentities/assign/action",
      "Microsoft.Resources/subscriptions/resourceGroups/read",

      "Microsoft.Storage/storageAccounts/write",
      "Microsoft.Storage/storageAccounts/blobServices/containers/write",

      "Microsoft.Insights/diagnosticSettings/*",
      # "Microsoft.Insights/diagnosticSettings/write",
      # "Microsoft.Insights/diagnosticSettings/read",
      # "Microsoft.Insights/diagnosticSettings/delete",

      "Microsoft.ContainerService/managedClusters/read",

    ]
    not_actions = []
  }
  assignable_scopes = [
    local.main_sub,
  ]
}

# resource "azurerm_role_assignment" "policy_assigment_main_custom" {
#   principal_id = azurerm_user_assigned_identity.policy_assignment.principal_id
#   scope        = local.main_sub

#   role_definition_id = azurerm_role_definition.policy_assignment.role_definition_resource_id
# }

resource "azurerm_role_assignment" "policy_assigment_monitor_contributor" {
  principal_id = azurerm_user_assigned_identity.policy_assignment.principal_id
  scope        = local.main_sub

  role_definition_name = "Monitoring Contributor"
}

# resource "azurerm_role_assignment" "policy_assigment_sa_contributor" {
#   principal_id = azurerm_user_assigned_identity.policy_assignment.principal_id
#   scope        = local.main_sub

#   role_definition_name = "Storage Account Contributor"
# }


# resource "azurerm_role_definition" "policy_assignment_def" {
#   name        = format("cyngular-readonly-role-%s", var.client_name)
#   description = "cyngular readonly role"

#   scope = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"
#   assignable_scopes = ["/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"]

#   permissions {
#     actions = [
#         "Microsoft.Authorization/*/read",

#     #   "Microsoft.Resources/subscriptions/resourceGroups/read",
#     #   "Microsoft.Resources/subscriptions/read",
#     #   "Microsoft.Management/managementGroups/read",
#     ]
#   }
# }

# resource "azurerm_role_assignment" "readonly" {
#   scope = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"

#   principal_id       = azuread_service_principal.client_sp.object_id
#   role_definition_id = azurerm_role_definition.policy_assignment_def.role_definition_resource_id
# }
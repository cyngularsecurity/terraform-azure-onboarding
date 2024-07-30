
# resource "azurerm_role_assignment" "role_assignment_subs" {
#   for_each = var.subscription_ids

#   scope                = "/subscriptions/${each.value}"
#   role_definition_name = var.role_name
#   principal_id         = var.service_principal_id
# }

resource "azurerm_role_assignment" "role_assignment_mgmt" {

  scope                = "/providers/Microsoft.Management/managementGroups/${var.mgmt_group_id}"
  role_definition_name = var.role_name
  principal_id         = var.service_principal_id
}


resource "azurerm_role_assignment" "role_assignment" {
  for_each = toset(var.subscriptions)

  scope                = "/subscriptions/${each.value}"
  role_definition_name = var.role_name
  principal_id         = var.service_principal_id
}

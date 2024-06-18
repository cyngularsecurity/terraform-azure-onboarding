
# resource "azurerm_subscription_policy_remediation" "aks" {
#   for_each     = toset(var.subscriptions)

#   name             = "cyngular-next-level-remediation"
#   subscription_id = "/subscriptions/${each.value}"
  
#   policy_assignment_id = azurerm_subscription_policy_assignment.aks_diagnostic_settings[each.key].id
  
#   # location_filters = var.client_locations
#   # resource_count       = 100
# }
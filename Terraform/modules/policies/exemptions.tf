# resource "azurerm_subscription_policy_exemption" "cyngular_client" {
#   for_each     = toset(var.subscriptions)
#   name         = "cyngular-${var.clien_name}-exemption"
#   display_name = "Cyngular Exemption"
#   description  = "This is an ongoing policy exemption"

#   subscription_id      = each.value
#   policy_assignment_id = azurerm_policy_assignment.activity_logs[each.key].id

#   exemption_category = "Waiver"
#   # expires_on           = "2030-12-31T23:59:59Z"

#   metadata = jsonencode({
#     "reason" : "Operational necessity"
#   })
# }


# resource "azurerm_subscription_policy_assignment" "diagnostic_settings_assignment" {
#   name                 = "enforce-diagnostic-settings"
#   scope                = "/subscriptions/${var.subscription_id}"
#   policy_definition_id = azurerm_policy_definition.diagnostic_settings_policy.id

#   display_name = "Apply diagnostic settings to all resources"
#   description  = "Ensure that diagnostic settings are applied to all resources in the subscription."

#   parameters = <<PARAMETERS
#   {
#     "storageAccountId": {
#       "value": "${var.storage_account_id}"
#     }
#     "categories": {
#       "value": ${jsonencode(var.log_categories)}
#     }
#   }
#   PARAMETERS
# }

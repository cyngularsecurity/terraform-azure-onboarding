
# resource "azurerm_policy_set_definition" "cyngular_general" {
#   name         = "cyngular_general"
#   policy_type  = "Custom"
#   display_name = "cyngular controller for audit logs, activity logs, nsg flow logs"

#   parameters = <<PARAMETERS
#     {
#         "allowedLocations": {
#             "type": "Array",
#             "metadata": {
#                 "description": "The list of allowed locations for resources.",
#                 "displayName": "Allowed locations",
#                 "strongType": "location"
#             }
#         }
#     }
# PARAMETERS

#   policy_definition_reference {
#     policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988"
#     parameter_values     = <<VALUE
#     {
#       "listOfAllowedLocations": {"value": "[parameters('allowedLocations')]"}
#     }
#     VALUE
#   }
# }
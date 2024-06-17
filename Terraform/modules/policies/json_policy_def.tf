
# resource "azurerm_policy_definition" "activity_logs" {
#   name        = "CyngularAuditEventPolicy"
#   policy_type = policy_def_json["policyType"]

#   mode = policy_def_json["mode"]
#   # All, Indexed, Microsoft.ContainerService.Data, Microsoft.CustomerLockbox.Data, Microsoft.DataCatalog.Data, Microsoft.KeyVault.Data, Microsoft.Kubernetes.Data, Microsoft.MachineLearningServices.Data, Microsoft.Network.Data and Microsoft.Synapse.Data

#   display_name = policy_def_json["displayName"]
#   description  = policy_def_json["description"]

#   metadata    = policy_def_json["metadata"]
#   policy_rule = policy_def_json["policyRule"]

#   parameters = jsonencode({
#     allowedLocations = {
#       value = var.client_locations
#     }
#     subscription_id = {
#       value = each.value
#     }
#   })
# }

# # resource "azurerm_policy_assignment" "activity_logs" {
# #   for_each             = toset(var.subscriptions)
# #   name                 = "activity-logs-policy-assignment-${local.main_location}"
# #   scope                = "/subscriptions/${each.value}"
# #   policy_definition_id = azurerm_policy_definition.activity_logs.id

# #   parameters = jsonencode({
# #     allowedLocations = {
# #       value = var.client_locations
# #     }
# #     subscription_id = {
# #       value = each.value
# #     }
# #   })

# #   location = local.main_location
# #   identity {
# #     type = "SystemAssigned"
# #   }
# # }
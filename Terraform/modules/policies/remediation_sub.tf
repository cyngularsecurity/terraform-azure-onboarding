
# # resource "azurerm_subscription_policy_remediation" "activity_logs" {
# #   count           = var.enable_activity_logs ? 1 : 0

# #   name            = "cyngular-${var.client_name}-actvity-logs-remediation-${var.subscription_name}"
# #   subscription_id = "/subscriptions/${var.subscription_id}"

# #   policy_assignment_id = azurerm_subscription_policy_assignment.activity_logs_diagnostic_settings[count.index].id
# #   location_filters     = var.client_locations

# #   failure_percentage   = 1.0
# #   parallel_deployments = 2
# #   # resource_discovery_mode = "ReEvaluateCompliance"
# # }

# # # resource "azurerm_subscription_policy_remediation" "audit_event" {
# # #   count        = var.enable_audit_events_logs ? 1 : 0
# # #   name            = "cyngular-${var.client_name}-audit-event-remediation-${var.subscription_name}"
# # #   subscription_id = "/subscriptions/${var.subscription_id}"

# # #   policy_assignment_id = azurerm_subscription_policy_assignment.audit_event_diagnostic_settings[count.index].id
# # #   location_filters = var.client_locations

# # #   failure_percentage = 1.0
# # #   parallel_deployments = 5
# # #   # resource_discovery_mode = "ReEvaluateCompliance"
# # # }

# # # resource "azurerm_subscription_policy_remediation" "nsg_flow_logs" {
# # #   count        = var.enable_flow_logs ? 1 : 0
# # #   name            = "cyngular-${var.client_name}-nsg-flow-logs-remediation-${var.subscription_name}"
# # #   subscription_id = "/subscriptions/${var.subscription_id}"

# # #   policy_assignment_id = azurerm_subscription_policy_assignment.nsg_flow_logs[count.index].id
# # #   location_filters = var.client_locations

# # #   failure_percentage = 1.0
# # #   parallel_deployments = 5
# # #   resource_discovery_mode = "ReEvaluateCompliance"
# # # }

# resource "azurerm_subscription_policy_remediation" "aks" {
#   count           = var.enable_aks_logs ? 1 : 0

#   name            = "cyngular-${var.client_name}-aks-remediation-${var.subscription_name}"
#   subscription_id = "/subscriptions/${var.subscription_id}"

#   policy_assignment_id = azurerm_subscription_policy_assignment.aks_diagnostic_settings[count.index].id
#   location_filters     = var.client_locations

#   failure_percentage   = 1.0
#   parallel_deployments = 5
#   # resource_count       = 500
#   # resource_discovery_mode = "ReEvaluateCompliance"
# }

resource "azurerm_subscription_policy_remediation" "aks" {
  count        = var.enable_aks_logs ? 1 : 0
  name            = "cyngular-${var.client_name}-aks-remediation"
  subscription_id = "/subscriptions/${var.subscription}"

  policy_assignment_id = azurerm_subscription_policy_assignment.aks_diagnostic_settings[count.index].id
  location_filters = var.client_locations
  
  failure_percentage = 1.0
  parallel_deployments = 5
  # resource_count       = 500
}

resource "azurerm_subscription_policy_remediation" "activity_logs" {
  count        = var.enable_aks_logs ? 1 : 0
  name            = "cyngular-${var.client_name}-aks-remediation"
  subscription_id = "/subscriptions/${var.subscription}"

  policy_assignment_id = azurerm_subscription_policy_assignment.aks_diagnostic_settings[count.index].id
  location_filters = var.client_locations
  
  failure_percentage = 1.0
  parallel_deployments = 5
}
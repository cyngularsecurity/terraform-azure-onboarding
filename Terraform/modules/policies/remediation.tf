
resource "azurerm_subscription_policy_remediation" "aks" {
  count        = var.enable_aks_logs ? 1 : 0
  name            = "cyngular-${var.client_name}-aks-remediation"
  subscription_id = "/subscriptions/${var.subscription}"

  policy_assignment_id = azurerm_subscription_policy_assignment.aks_diagnostic_settings.id

  # location_filters = var.client_locations
  # resource_count       = 100
}
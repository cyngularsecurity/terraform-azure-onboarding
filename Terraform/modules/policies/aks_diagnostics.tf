resource "azurerm_policy_definition" "aks_diagnostic_settings_policy" {
  name         = "require-aks-diagnostic-settings"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require Diagnostic Settings for AKS Clusters"
  description  = "Ensures that AKS clusters have diagnostic settings configured to send logs to the specified storage account."

  metadata = jsonencode({ category = "Monitoring" })

  policy_rule = jsonencode({
    if = {
      field = "type"
      equals = "Microsoft.ContainerService/managedClusters"
    }
    then = {
      effect = "AuditIfNotExists"
      details = {
        type = "Microsoft.Insights/diagnosticSettings"
        existenceCondition = {
          allOf = [
            {
              field = "Microsoft.Insights/diagnosticSettings/logs[*].category"
              equals = "kube-audit"
            },
            {
              field = "Microsoft.Insights/diagnosticSettings/logs.enabled"
              equals = "true"
            },
            {
              field = "Microsoft.Insights/diagnosticSettings/storageAccountId"
              in = "[parameters('storageAccountIds')]"
            }
          ]
        }
      }
    }
  })

  parameters = jsonencode({
    storageAccountIds = {
      type = "Array"
      metadata = {
        description = "A list of storage account IDs where the logs should be sent."
        displayName = "Storage Account IDs"
        defaultValue = jsonencode([
          for location, ids in var.default_storage_accounts : {
            location = location
            ids      = ids
          }
        ])
      }
    }
  })
}

# resource "azurerm_subscription_policy_assignment" "aks_diagnostic_settings_policy_assignment" {
#   name                 = "require-aks-diagnostic-settings-assignment"
#   policy_definition_id = azurerm_policy_definition.aks_diagnostic_settings_policy.id
#   subscription_id      = "/subscriptions/${var.subscription}"

#   display_name         = "Require Diagnostic Settings for AKS Clusters"

  # parameters = jsonencode({
  #   storageAccountIds = {
  #     value = values(var.location_storage_account_map)
  #   }
  # })
# }

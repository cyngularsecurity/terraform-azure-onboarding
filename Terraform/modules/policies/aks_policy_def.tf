resource "azurerm_policy_definition" "aks_diagnostic_settings" {
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
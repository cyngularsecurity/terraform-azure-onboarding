
resource "azurerm_monitor_diagnostic_setting" "activity_logs" {
  count = var.enable_audit_events_logs ? 1 : 0
  # name               = "CyngularDiagnostic"
  name               = "CyngularDiagnostic-${var.client_name}"
  target_resource_id = "/subscriptions/${var.subscription}"
  storage_account_id = lookup(var.default_storage_accounts, keys(var.default_storage_accounts)[0], null)

  enabled_log { // ACTIVITY_LOGS
    category = "Recommendation"

    retention_policy {
      enabled = false
      days    = 30
    }
  }
  enabled_log {
    category = "Alert"

    retention_policy {
      enabled = false
      days    = 30
    }
  }
  enabled_log {
    category = "ServiceHealth"

    retention_policy {
      enabled = false
      days    = 30
    }
  }
  enabled_log {
    category = "Administrative"

    retention_policy {
      enabled = false
      days    = 30
    }
  }
  enabled_log {
    category = "Security"

    retention_policy {
      enabled = false
      days    = 30
    }
  }

  enabled_log {
    category = "Policy"

    retention_policy {
      enabled = false
      days    = 30
    }
  }
  enabled_log {
    category = "Autoscale"

    retention_policy {
      enabled = false
      days    = 30
    }
  }
  enabled_log {
    category = "ResourceHealth"

    retention_policy {
      enabled = false
      days    = 30
    }
  }
}
locals {
  aad_diagnostic_categories = [
    "AuditLogs",
    "SignInLogs",
    "NonInteractiveUserSignInLogs",
    "ServicePrincipalSignInLogs",
    "ManagedIdentitySignInLogs",
    "ProvisioningLogs",
    "ADFSSignInLogs",
    "NetworkAccessTrafficLogs",
    "EnrichedOffice365AuditLogs",
    "MicrosoftGraphActivityLogs",
    "RemoteNetworkHealthLogs",
    "UserRiskEvents",
    "ServicePrincipalRiskEvents",
    "RiskyUsers",
    "RiskyServicePrincipals",
    "NetworkAccessAlerts"
  ]

  main_location = element(var.locations, 0)

  aad_ds = {
    name              = "cyngular-audit-logs-${var.client_name}"
    retention_enabled = false
    retention_days    = 1
  }
}

resource "azurerm_monitor_aad_diagnostic_setting" "cyngular_audit_logs" {
  name               = local.aad_ds.name
  storage_account_id = var.default_storage_accounts[local.main_location]

  dynamic "enabled_log" {
    for_each = toset(local.aad_diagnostic_categories)
    content {
      category = enabled_log.value
      # retention_policy {
      # enabled = local.aad_ds.retention_enabled
      #   days    = local.aad_ds.retention_days
      # }
    }
  }
}
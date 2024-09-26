locals {
  aad_diagnostic_categories = [
    "AuditLogs",
    "SignInLogs",
    "NonInteractiveUserSignInLogs",
    "ServicePrincipalSignInLogs",
    "ManagedIdentitySignInLogs",
    "ProvisioningLogs",
    "ADFSSignInLogs",
    "RiskyUsers",
    "UserRiskEvents",
    "NetworkAccessTrafficLogs",
    "RiskyServicePrincipals",
    "ServicePrincipalRiskEvents",
    "EnrichedOffice365AuditLogs",
    "MicrosoftGraphActivityLogs",
    "RemoteNetworkHealthLogs"
  ]

  main_location = element(var.locations, 0)

  aad_diagnostic_settings = {
    name              = "cyngular-audit-logs"
    retention_enabled = true
    retention_days    = 1
  }
}

resource "azurerm_monitor_aad_diagnostic_setting" "cyngular_audit_logs" {
  name               = local.aad_diagnostic_settings.name
  storage_account_id = azurerm_storage_account.example.id

  dynamic "enabled_log" {
    for_each = toset(local.aad_diagnostic_categories)
    content {
      category = enabled_log.value
      retention_policy {
        enabled = local.aad_diagnostic_settings.retention_enabled
        # days    = local.aad_diagnostic_settings.retention_days
      }
    }
  }
}
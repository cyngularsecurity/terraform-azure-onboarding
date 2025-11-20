locals {
  aad_ds = {
    name = "cyngular-audit-logs-${var.client_name}"
    categories = [
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
  }
}
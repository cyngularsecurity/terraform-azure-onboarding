locals {
  common_storage_account_tags = {
    cyngular-auditevents = var.enable_audit_events_logs
    cyngular-nsgflowlogs = var.enable_flow_logs
    cyngular-aks         = var.enable_aks_logs

    cyngular-client = var.client_name
  }

  main_storage_account_tags = merge(local.common_storage_account_tags, {
    cyngular-os           = true
    cyngular-visibility   = true
    cyngular-auditlogs    = var.enable_audit_logs
    cyngular-activitylogs = var.enable_activity_logs
  })


  required_providers_registrations = toset([
      "Microsoft.Storage",
      "Microsoft.Web",
      "Microsoft.OperationalInsights",
      "Microsoft.ManagedIdentity",
      "Microsoft.Authorization",
      "Microsoft.Resources",
    ])
}
data "azuread_client_config" "current" {}

locals {
  main_location = var.locations[0]

  common_storage_account_tags = {
    cyngular-auditevents = var.enable_audit_events_logs
    cyngular-nsgflowlogs = var.enable_flow_logs
    cyngular-aks         = var.enable_aks_logs
  }

  main_storage_account_tags = merge(local.common_storage_account_tags, {
    cyngular-os           = true
    cyngular-visibility   = true
    cyngular-auditlogs    = var.enable_audit_logs
    cyngular-activitylogs = var.enable_activity_logs
  })
}
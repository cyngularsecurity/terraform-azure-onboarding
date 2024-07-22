data "azuread_client_config" "current" {}

locals {
    mgmt_group_id = data.azuread_client_config.current.tenant_id
    storage_acount_tags     = {
    cyngular-auditlogs = "" # TODO
    cyngular-activitylogs = var.enable_activity_logs
    cyngular-auditevents = var.enable_audit_events_logs
    cyngular-nsgflowlogs = var.enable_flow_logs
    cyngular-aks = var.enable_aks_logs
  }
}
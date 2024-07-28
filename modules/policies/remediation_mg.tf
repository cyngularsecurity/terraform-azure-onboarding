resource "azurerm_management_group_policy_remediation" "activity_logs" {
  count           = var.enable_activity_logs ? 1 : 0

  name         = "cyngular-activity-logs-${var.client_name}"
  management_group_id  = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"

  policy_assignment_id = azurerm_management_group_policy_assignment.activity_logs[count.index].id
  location_filters     = var.client_locations

  failure_percentage   = 1.0
  parallel_deployments = 2
  # resource_discovery_mode = "ReEvaluateCompliance"
}
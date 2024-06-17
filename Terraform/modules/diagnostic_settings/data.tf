
data "external" "resource_ids" {
  for_each = var.enable_activity_logs || var.enable_audit_events_logs ? toset(var.sub_resource_group_names) : []
  program  = ["bash", "${path.module}/list_resources_ids.sh"]

  query = {
    subscription_id  = var.subscription
    resource_group   = each.value
    client_locations = join(",", var.client_locations)
    excluded_types   = local.excluded_types
  }
}

data "external" "resource_locations" {
  for_each = var.enable_audit_events_logs ? toset(var.sub_resource_group_names) : []
  program  = ["bash", "${path.module}/list_resources_locations.sh"]

  query = {
    subscription_id  = var.subscription
    resource_group   = each.value
    client_locations = join(",", var.client_locations)
    excluded_types   = local.excluded_types
  }
}
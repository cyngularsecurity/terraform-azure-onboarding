data "external" "locations_without_net_watcher" {
  program = ["bash", "${path.module}/list_net_watchers.sh"]

  query = {
    subscription_id  = var.subscription
    client_locations = join(",", var.client_locations)
  }
}

data "external" "nsgs_without_flow_logs" {
  for_each = toset(var.sub_resource_group_names)
  program  = ["bash", "${path.module}/list_filtered_nsgs.sh"]

  query = {
    subscription_id  = var.subscription
    resource_group   = each.value
    client_locations = join(",", var.client_locations)
  }
}
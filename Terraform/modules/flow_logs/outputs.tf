
output "nsgs_without_flow_logs" {
  value = local.sub_nsgs_without_flow_logs
}

output "locations_without_net_watcher" {
  value = local.locations_without_net_watchers
}
locals {
  network_watcher_details = {
    for location, id in data.external.locations_without_net_watcher.result : location => {
      id             = id
      resource_group = id != "" ? split("/", id)[4] : ""
    }
  }
  locations_without_net_watchers = {
    for location, details in local.network_watcher_details : location => details
    if details.id == ""
  }
  sub_nsgs_without_flow_logs = flatten([
    for rg in var.sub_resource_group_names : [
      for nsg_name, nsg_location in try(data.external.nsgs_without_flow_logs[rg].result, {}) : {
        nsg_name       = nsg_name
        nsg_location   = nsg_location
        resource_group = rg
      }
    ]
  ])
}

# # output "admin_consent_url" {
# #   value = "######## admin consent url: https://login.microsoftonline.com/organizations/adminconsent?client_id=${var.application_id} #######"
# # }

output "locations_without_net_watcher" {
  value = {
    for sub in local.subscriptions :
    sub => flatten([
      for r in try(module.nsg_flow_logs[sub].locations_without_net_watcher, []) : r
    ])
  }
}

output "nsgs_without_flow_logs" {
  value = {
    for sub in local.subscriptions :
    sub => flatten([
      for r in try(module.nsg_flow_logs[sub].nsgs_without_flow_logs, []) : r
    ])
  }
}

output "sub_resource_ids" {
  value = {
    for sub in local.subscriptions :
    sub => flatten([
      for r in try(module.diagnostic_settings[sub].sub_resource_ids, []) : r
    ])
  }
}

output "resource_groups" {
  value = {
    for sub in local.subscriptions :
    sub => flatten([
      for r in module.middler[sub].resource_groups : r
    ])
  }
}
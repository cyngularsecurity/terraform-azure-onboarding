
# # output "admin_consent_url" {
# #   value = "######## admin consent url: https://login.microsoftonline.com/organizations/adminconsent?client_id=${var.application_id} #######"
# # }

output "root_mgmt_group_info" {
  value = data.azurerm_management_group.root
}

# output "locations_without_net_watcher" {
#   value = {
#     for sub in local.subscriptions :
#     sub => flatten([
#       for r in try(module.nsg_flow_logs[sub].locations_without_net_watcher, []) : r
#     ])
#   }
# }

# # output "admin_consent_url" {
# #   value = "######## admin consent url: https://login.microsoftonline.com/organizations/adminconsent?client_id=${var.application_id} #######"
# # }

# output "sub_resources" {
#   value = {
#     for rg in var.sub_resource_group_names : rg => flatten([
#       for resource in data.azurerm_resources.sub_resources[rg].resources : {
#         id       = resource.id
#         type     = resource.type
#         location = resource.location
#       }
#   ])
#   }
# }

output "resource_groups" {
  value = [flatten(local.sub_resource_groups)]
}
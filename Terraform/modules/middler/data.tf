
# data "azurerm_resources" "sub_resources" {
#   for_each            = toset(local.sub_resource_groups)
#   resource_group_name = each.value
# }

data "external" "resource_groups" {
  program = ["bash", "${path.module}/list_resource_groups.sh"]

  query = {
    subscription_id  = var.subscription
    client_locations = join(",", var.client_locations)
  }
}
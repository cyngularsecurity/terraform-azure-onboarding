data "azuread_client_config" "current" {}
data "azuread_application_published_app_ids" "well_known" {}
data "azurerm_subscriptions" "available" {}

data "external" "resource_groups" {
  for_each = toset(local.subscriptions)

  program = ["bash", "${path.module}/scripts/list_resource_groups.sh"]
  query = {
    subscription_id  = each.value
    client_locations = join(",", var.locations)
  }
}
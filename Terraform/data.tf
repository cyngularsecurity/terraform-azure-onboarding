data "azuread_client_config" "current" {}
data "azuread_application_published_app_ids" "well_known" {}
data "azurerm_subscriptions" "available" {}

# data "azurerm_management_group" "tenant_root" {
#   name = "root"
#   # name = data.azuread_client_config.current.tenant_id
# }

# data "azurerm_management_group" "sub_mg" {
#   for_each = { for sub in var.subscriptions_data : sub.subscription_id => sub }
#   name     = each.value.mgmt_group_name
# }
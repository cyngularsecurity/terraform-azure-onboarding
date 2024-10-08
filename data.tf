data "azuread_client_config" "current" {}
data "azuread_application_published_app_ids" "well_known" {}
data "azurerm_subscriptions" "available" {}

data "azurerm_management_group" "root" {
  display_name = "Tenant Root Group"
}

resource "random_string" "suffix" {
  length  = 7
  numeric = true
  special = false
  upper   = false
}
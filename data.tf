data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

data "azurerm_subscriptions" "available" {}

data "azuread_application_published_app_ids" "well_known" {}

data "azurerm_management_group" "root" {
  display_name = "Tenant Root Group"
}

resource "random_string" "suffix" {
  length  = 7
  numeric = true
  special = false
  upper   = false
}
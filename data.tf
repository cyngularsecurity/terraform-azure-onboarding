data "azurerm_client_config" "current" {}
# data "azuread_client_config" "current" {}
data "azurerm_subscription" "current" {}

data "azuread_application_published_app_ids" "well_known" {}

data "http" "local_ip" {
  url = "https://checkip.amazonaws.com"

  request_headers = {
    Accept = "application/json"
  }
} 

data "azurerm_management_group" "root" {
  name = data.azurerm_client_config.current.tenant_id
}
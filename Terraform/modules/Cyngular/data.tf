data "azuread_client_config" "current" {}

locals {
    mgmt_group_id = data.azuread_client_config.current.tenant_id
}
locals {
  roles           = toset(jsondecode(var.roles_json))
  subscriptions   = toset(data.azurerm_subscriptions.available.subscriptions[*].subscription_id)
  main_location   = element(var.locations, 0)
  resource_prefix = format("cyngular-%s", var.client_name)
  # resources = flatten([
  #   for sub in var.subscriptions : jsondecode(file("${path.module}/resources_${sub}.json")).resources
  # id = resource.id
  # ])
}

module "main" {
  source = "./modules/cyngular"

  client_name   = var.client_name
  tags          = var.tags
  main_location = local.main_location

  locations           = var.locations
  preffix             = local.resource_prefix
  application_id      = var.application_id
  msgraph_id          = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  current_user_obj_id = data.azuread_client_config.current.object_id
}

module "role_assignment" {
  source   = "./modules/role_assignment"
  for_each = local.roles

  role_name            = each.value
  subscriptions        = local.subscriptions
  service_principal_id = module.main.sp_id
}

module "diagnostic_settings" {
  source   = "./modules/diagnostic_settings"
  for_each = local.subscriptions

  client_name              = var.client_name
  client_locations         = var.locations
  subscription             = each.value
  sub_resource_group_names = values(data.external.resource_groups[each.value].result)
  default_storage_accounts = module.main.storage_accounts_ids
}

locals {
  roles           = toset(jsondecode(var.roles_json))
  main_location   = element(var.locations, 0)
  resource_prefix = format("cyngular-%s", var.client_name)

  subscriptions = toset(data.azurerm_subscriptions.available.subscriptions[*].subscription_id)
  subscriptions_data = { for i, sub in data.azurerm_subscriptions.available.subscriptions : i => {
    id   = sub.subscription_id
    name = lower(replace(sub.display_name, " ", "_"))
    }
  }
  sub_ids   = { for i, sub in local.subscriptions_data : i => sub.id }
  sub_names = { for i, sub in local.subscriptions_data : i => sub.name }
  mgmt_group_id = data.azuread_client_config.current.tenant_id
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

  mgmt_group_id = local.mgmt_group_id
  role_name            = each.value
  subscription_ids     = { for i, sub in local.subscriptions_data : i => sub.id }
  service_principal_id = module.main.sp_id
}

# module "policy_assigments" {
#   source     = "./modules/policies"
#   depends_on = [module.role_assignment]

#   subscription_ids   = local.sub_ids
#   subscription_names = local.sub_names

#   prefix           = local.resource_prefix
#   tags             = var.tags
#   main_location    = local.main_location
#   cyngular_rg_name = module.main.client_rg

#   client_name              = var.client_name
#   client_locations         = var.locations
#   default_storage_accounts = module.main.storage_accounts_ids

#   enable_activity_logs     = var.enable_activity_logs
#   enable_audit_events_logs = var.enable_audit_events_logs
#   enable_flow_logs         = var.enable_flow_logs
#   enable_aks_logs          = var.enable_aks_logs
# }

module "cyngular_function" {
  source     = "./modules/policies"
  depends_on = [module.role_assignment]

  subscription_ids   = local.sub_ids
  subscription_names = local.sub_names

  tags             = var.tags
  main_location    = local.main_location
  cyngular_rg_name = module.main.client_rg

  client_name              = var.client_name
  client_locations         = var.locations
  default_storage_accounts = module.main.storage_accounts_ids

  enable_activity_logs     = var.enable_activity_logs
  enable_audit_events_logs = var.enable_audit_events_logs
  enable_flow_logs         = var.enable_flow_logs
  enable_aks_logs          = var.enable_aks_logs
}
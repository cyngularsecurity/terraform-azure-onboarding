locals {
  roles           = toset(jsondecode(var.roles_json))
  main_location   = element(var.locations, 0)
  resource_prefix = format("cyngular-%s", var.client_name)

  subscriptions      = toset(data.azurerm_subscriptions.available.subscriptions[*].subscription_id)
  subscriptions_data = data.azurerm_subscriptions.available.subscriptions
  # subscriptions = toset(["b682a811-395f-4eae-828b-b099faf3fe44", "373cb248-9e3b-4f65-8174-c72d253103ea"]) // sandbox
  # subscriptions = toset(["b6c14413-fb13-4063-acd5-d47e2537a7ba"]) // client
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
  depends_on = [ module.main ]

  role_name            = each.value
  subscriptions        = local.subscriptions
  service_principal_id = module.main.sp_id
}

# module "middler" {
#   source   = "./modules/middler"
#   for_each = local.subscriptions
#   # for_each = toset(local.subscriptions_data).subscription_id
  
#   depends_on = [
#     module.role_assignment,
#     module.main,
#   ]

#   subscription     = each.value
#   client_name      = var.client_name
#   client_locations = var.locations
# }

# module "diagnostic_settings" {
#   source     = "./modules/diagnostic_settings"
#   for_each   = var.enable_activity_logs || var.enable_audit_events_logs ? local.subscriptions : []
#   depends_on = [module.role_assignment]

#   subscription     = each.value
#   client_name      = var.client_name
#   client_locations = var.locations

#   enable_activity_logs     = var.enable_activity_logs
#   enable_audit_events_logs = var.enable_audit_events_logs
#   default_storage_accounts = module.main.storage_accounts_ids

#   sub_resource_group_names = flatten([for rg in module.middler[each.value].resource_groups : rg])
# }

# module "nsg_flow_logs" {
#   source   = "./modules/flow_logs"
#   for_each = var.enable_flow_logs ? local.subscriptions : []

#   subscription             = each.value
#   prefix           = local.resource_prefix
#   tags             = var.tags
#   main_location    = local.main_location
#   cyngular_rg_name = module.main.client_rg

#   client_name      = var.client_name
#   client_locations = var.locations

#   sub_resource_group_names = flatten([for rg in module.middler[each.value].resource_groups : rg])
#   default_storage_accounts = module.main.storage_accounts_ids
# }

module "policy_assigments" {
  source = "./modules/policies"
  for_each = { for sub in local.subscriptions_data : sub.subscription_id => {
    id   = sub.subscription_id
    name = sub.display_name
    }
  }
  depends_on = [module.role_assignment]

  subscription_id   = each.value.id
  subscription_name = lower(replace(each.value.name, " ", "_"))

  prefix           = local.resource_prefix
  tags             = var.tags
  main_location    = local.main_location
  cyngular_rg_name = module.main.client_rg

  client_name              = var.client_name
  client_locations         = var.locations
  default_storage_accounts = module.main.storage_accounts_ids

  enable_activity_logs     = "true"
  enable_audit_events_logs = "true"
  enable_flow_logs         = "true"
  enable_aks_logs          = "true"

  # enable_activity_logs     = var.enable_activity_logs
  # enable_audit_events_logs = var.enable_audit_events_logs
  # enable_flow_logs         = var.enable_flow_logs
  # enable_aks_logs          = var.enable_aks_logs

  # sub_resource_group_names = flatten([for rg in module.middler[each.value].resource_groups : rg])
}

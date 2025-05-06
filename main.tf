module "main" {
  source = "./modules/Cyngular"

  client_name = var.client_name
  locations   = var.locations

  tags          = local.tags
  main_location = local.main_location
  prefix        = local.resource_prefix
  suffix        = local.random_suffix

  application_id = var.application_id
  msgraph_id     = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

  current_user_obj_id = local.config.object_id

  enable_audit_logs        = var.enable_audit_logs
  enable_activity_logs     = var.enable_activity_logs
  enable_audit_events_logs = var.enable_audit_events_logs
  enable_flow_logs         = var.enable_flow_logs
  enable_aks_logs          = var.enable_aks_logs
}

module "role_assignment" {
  source   = "./modules/role_assignment"
  for_each = local.roles

  mgmt_group_id        = local.mgmt_group_id
  role_name            = each.value
  service_principal_id = module.main.sp_id

  depends_on = [module.main]
}

module "cyngular_function" {
  source = "./modules/function"

  tags        = local.tags
  client_name = var.client_name

  suffix = local.random_suffix

  app_insights_unsupported_locations = local.app_insights_unsupported_locations
  main_location                      = local.main_location
  client_locations                   = var.locations

  cyngular_rg_name = module.main.client_rg.name

  default_storage_accounts = module.main.storage_accounts_ids

  enable_activity_logs     = var.enable_activity_logs
  enable_audit_events_logs = var.enable_audit_events_logs
  enable_flow_logs         = var.enable_flow_logs
  enable_aks_logs          = var.enable_aks_logs

  allow_function_logging = var.allow_function_logging

  mgmt_group_id = local.mgmt_group_id

  # local_os                       = var.local_os
  # cyngular_rg_id           = module.main.client_rg.id
  # cyngular_rg_location     = module.main.client_rg.location
  # main_subscription_id = var.main_subscription_id

  depends_on = [module.main]
}

module "audit_logs" {
  source = "./modules/audit_logs"
  count  = var.enable_audit_logs == true ? 1 : 0

  main_location = local.main_location
  client_name   = var.client_name

  default_storage_accounts = module.main.storage_accounts_ids

  # cyngular_rg_name         = module.main.client_rg.name
  # suffix = local.random_suffix
  # tags             = local.tags
}
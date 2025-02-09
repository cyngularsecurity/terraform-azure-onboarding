module "main" {
  source = "./modules/Cyngular"

  tags          = local.tags
  client_name   = var.client_name
  main_location = local.main_location
  locations = var.locations

  prefix    = local.resource_prefix
  suffix    = random_string.suffix.result

  application_id      = var.application_id
  msgraph_id          = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

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

  mgmt_group_id        = local.mgmt_group_id
  subscription_ids = local.sub_ids

  tags             = local.tags
  client_name      = var.client_name

  suffix = random_string.suffix.result
  main_subscription_id = var.main_subscription_id

  app_insights_unsupported_locations = local.app_insights_unsupported_locations
  main_location    = local.cyngular_function_location
  client_locations = var.locations

  local_os                       = var.local_os
  cyngular_rg_name         = module.main.client_rg.name
  cyngular_rg_id           = module.main.client_rg.id
  cyngular_rg_location     = module.main.client_rg.location

  default_storage_accounts = module.main.storage_accounts_ids

  enable_activity_logs     = var.enable_activity_logs
  enable_audit_events_logs = var.enable_audit_events_logs
  enable_flow_logs         = var.enable_flow_logs
  enable_aks_logs          = var.enable_aks_logs

  depends_on = [module.main]
}

module "audit_logs" {
  source = "./modules/audit_logs"
  count  = var.enable_audit_logs == true ? 1 : 0

  locations = var.locations

  subscription_ids = local.sub_ids
  suffix = random_string.suffix.result

  tags             = local.tags
  main_location    = local.main_location
  client_name      = var.client_name

  cyngular_rg_name         = module.main.client_rg.name

  default_storage_accounts = module.main.storage_accounts_ids
}
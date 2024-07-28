locals {
  roles           = toset(jsondecode(<<EOF
  [
    "Reader",
    "Disk Pool Operator",
    "Data Operator for Managed Disks",
    "Disk Snapshot Contributor",
    "Microsoft Sentinel Reader",
    "API Management Workspace Reader",
    "Reader and Data Access",
    "Managed Applications Reader"
  ]
  EOF
  ))
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

  tags = {
    Owner = "Cyngular"
  }
}

module "main" {
  source = "./modules/cyngular"

  client_name   = var.client_name
  tags          = local.tags
  main_location = local.main_location

  locations           = var.locations
  prefix             = local.resource_prefix
  application_id      = var.application_id
  msgraph_id          = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  current_user_obj_id = data.azuread_client_config.current.object_id

  enable_audit_logs = var.enable_audit_logs
  enable_activity_logs     = var.enable_activity_logs
  enable_audit_events_logs = var.enable_audit_events_logs
  enable_flow_logs         = var.enable_flow_logs
  enable_aks_logs          = var.enable_aks_logs
}

module "role_assignment" {
  source   = "./modules/role_assignment"
  for_each = local.roles

  mgmt_group_id = local.mgmt_group_id
  role_name            = each.value
  # subscription_ids     = { for i, sub in local.subscriptions_data : i => sub.id }
  service_principal_id = module.main.sp_id
}

module "cyngular_function" {
  source     = "./modules/function"
  # depends_on = [module.role_assignment]

  subscription_ids   = local.sub_ids
  subscription_names = local.sub_names

  tags             = local.tags
  main_location    = local.main_location
  client_locations         = var.locations
  client_name              = var.client_name
  
  cyngular_rg_name = module.main.client_rg
  default_storage_accounts = module.main.storage_accounts_ids

  enable_activity_logs     = var.enable_activity_logs
  enable_audit_events_logs = var.enable_audit_events_logs
  enable_flow_logs         = var.enable_flow_logs
  enable_aks_logs          = var.enable_aks_logs

  service_zip = data.archive_file.cyngular_function.output_path
}

locals {
  roles = toset(jsondecode(<<EOF
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

  config = data.azuread_client_config.current

  app_insights_unsupported_locations = ["israelcentral"]

  # main_location   = element(var.locations, 0)
  main_location = var.main_location != "" ? var.main_location : element(var.locations, 0)

  # cyngular_function_location = contains(local.app_insights_unsupported_locations, var.main_location) ? element([for loc in var.locations : loc if loc != "israelcentral"], 0) : var.main_location
  cyngular_function_location = local.main_location

  resource_prefix = format("cyngular-%s", var.client_name)

  subscriptions_data = { for i, sub in data.azurerm_subscriptions.available.subscriptions : i => {
    id   = sub.subscription_id
    name = lower(replace(sub.display_name, " ", "_"))
    }
  }
  sub_ids       = { for i, sub in local.subscriptions_data : i => sub.id }
  mgmt_group_id = local.config.tenant_id

  tags = {
    Vendor = "Cyngular Security"
  }
}
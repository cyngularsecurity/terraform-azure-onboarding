
resource "azurerm_network_watcher" "new_network_watchers" {
  for_each = length(local.locations_without_net_watchers) > 0 ? local.locations_without_net_watchers : {}

  name                = "NetworkWatcher_${each.key}"
  location            = each.key
  resource_group_name = var.cyngular_rg_name
}

resource "azurerm_network_watcher_flow_log" "cyngular_flow_logs" {
  for_each = length(local.sub_nsgs_without_flow_logs) > 0 ? {
    for nsg in local.sub_nsgs_without_flow_logs : "${nsg.resource_group}-${nsg.nsg_name}" => nsg
  } : {}

  name                 = "cyngular-${each.key}"
  network_watcher_name = "NetworkWatcher_${each.value.nsg_location}"

  resource_group_name = each.value.nsg_location != "" ? (
    lookup(local.network_watcher_details, each.value.nsg_location, {}).resource_group != "" ?
    lookup(local.network_watcher_details, each.value.nsg_location, {}).resource_group :
    var.cyngular_rg_name
  ) : var.cyngular_rg_name

  network_security_group_id = "/subscriptions/${var.subscription}/resourceGroups/${each.value.resource_group}/providers/Microsoft.Network/networkSecurityGroups/${each.value.nsg_name}"

  storage_account_id = var.default_storage_accounts[each.value.nsg_location]
  enabled            = true

  retention_policy {
    enabled = true
    days    = 7
  }
}

# resource "azurerm_monitor_diagnostic_setting" "audit_events_logs" {
#   for_each = {
#     for subscription in var.subscriptions : subscription => {
#       for resource in local.resources[subscription] : resource => resource
#     }
#   }

#   name               = "CyngularDiagnostic"
#   target_resource_id = each.value
#   storage_account_id = var.storage_account_id

#   dynamic "log" {
#     for_each = local.logs[each.value]

#     content {
#       category = log.value.category
#       enabled  = log.value.enabled
#       retention_policy {
#         enabled = log.value.retention_policy.enabled
#         days    = log.value.retention_policy.days
#       }
#     }
#   }
# }


# resource "azurerm_monitor_diagnostic_setting" "nsg_flow_logs" {
#   for_each = {
#       for resource in local.resources[subscription] : resource => resource
#     }
#   }

#   name               = "CyngularDiagnostic"
#   target_resource_id = each.value
#   storage_account_id = var.storage_account_id

#   dynamic "log" {
#     for_each = local.logs[each.value]

#     content {
#       category = log.value.category
#       enabled  = log.value.enabled
#       retention_policy {
#         enabled = log.value.retention_policy.enabled
#         days    = log.value.retention_policy.days
#       }
#     }
#   }
# }

# resource "azurerm_monitor_diagnostic_setting" "diagnostic_settings" {
#   for_each = { for subscription in var.subscriptions : subscription => data.azurerm_resources.resources[subscription].resources }

#   name               = "CyngularDiagnostic"
#   target_resource_id = each.value.id
#   storage_account_id = var.storage_account_id

#   dynamic "log" {
#     for_each = toset(lookup(local.log_settings, each.value.type, local.default_log_settings))
#     content {
#       category = log.value.category
#       enabled  = log.value.enabled
#       retention_policy {
#         enabled = log.value.retention_policy.enabled
#         days    = log.value.retention_policy.days
#       }
#     }
#   }
# }

# locals {
#   log_settings = {
#     "Microsoft.Sql/servers"        = jsondecode(var.all_and_audit_log_settings),
#     "Microsoft.DBforMySQL/servers" = jsondecode(var.all_and_audit_log_settings),
#     "Microsoft.Network/networkSecurityGroups" = jsondecode(var.all_logs_setting),
#     "Microsoft.Network/bastionHosts" = jsondecode(var.all_logs_setting),
#     "Microsoft.Compute/virtualMachines" = jsondecode(var.audit_event_log_settings)
#     // Add more resource types and their respective log settings here
#   }
# }

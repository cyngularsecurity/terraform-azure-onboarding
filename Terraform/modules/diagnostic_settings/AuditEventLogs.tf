# resource "azurerm_monitor_diagnostic_setting" "audit_event" {
#   for_each = { for i, resource in local.flattened_resources : i => resource }

#   name               = "CyngularDiagnostic"
#   target_resource_id = each.value.id
#   storage_account_id = lookup(var.default_storage_accounts, each.value.type, null)


#   enabled_log { // ALL_LOGS | ALL_AND_AUDIT_LOGS
#     category = "allLogs"
#     enabled  = true

#     retention_policy {
#       enabled = false
#       days    = 30
#     }
#   }

#   enabled_log { // ALL_AND_AUDIT_LOGS
#     category = "audit"
#     enabled  = true

#     retention_policy {
#       enabled = false
#       days    = 30
#     }
#   }

#   enabled_log { // AUDIT_EVENT_LOGS ** ALL
#     category = "AuditEvent"
#     enabled  = true

#     retention_policy {
#       enabled = false
#       days    = 30
#     }
#   }
# }

resource "azurerm_monitor_diagnostic_setting" "audit_event" {
  for_each = {
    for i, resource in local.flattened_resources :
    i => resource if lookup(local.resource_log_settings, resource.type, null) != null &&
    contains(var.client_locations, resource.location)
  }

  name               = "CyngularDiagnostic-${var.client_name}"
  target_resource_id = each.value.id

  storage_account_id = var.default_storage_accounts[each.value.location]
  # storage_account_id = lookup(var.default_storage_accounts, each.value.location, null)
  # storage_account_id = lookup(var.aks_storage_accounts, each.value.location, var.default_storage_accounts[each.value.location])

  dynamic "log" {
    for_each = lookup(local.resource_log_settings[each.value.type], "categories", [])

    content {
      category = log.value
      enabled  = true

      retention_policy {
        enabled = false
        days    = lookup(local.resource_log_settings[each.value.type], "retention", 0)
      }
    }
  }
}
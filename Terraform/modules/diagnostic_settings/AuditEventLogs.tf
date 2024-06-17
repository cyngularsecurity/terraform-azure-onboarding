resource "azurerm_monitor_diagnostic_setting" "audit_event" {
  for_each = {
    for i, r_id in local.sub_resource_ids : i => r_id
  }

  name               = "CyngularDiagnostic-${var.client_name}"
  target_resource_id = each.value

  storage_account_id = var.default_storage_accounts[element(local.sub_resource_locations, each.key)]

  dynamic "enabled_log" {
    for_each = split(",", local.categorize[element(local.sub_resource_ids, each.key)].value)

    content {
      category       = local.categorize[element(local.sub_resource_ids, each.key)].type == "category" ? enabled_log.value : null
      category_group = local.categorize[element(local.sub_resource_ids, each.key)].type == "category_group" ? enabled_log.value : null
    }
  }
  lifecycle {
    ignore_changes = [
      metric, # Ignore changes to all metric blocks
      # "metric.category",  # Alternatively, ignore specific attributes within the metric block
      # "metric.retention_policy", # Or ignore the retention_policy block
    ]
  }
}

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

# resource "azurerm_monitor_diagnostic_setting" "audit_event" {
#   # for_each = { for i, r_id in var.sub_resources_ids : i => r_id }
#   for_each = local.resource_names

# #   # name               = "CyngularDiagnostic"
#   name               = "CyngularDiagnostic-${var.client_name}"
#   target_resource_id = each.value

#   storage_account_id = var.default_storage_accounts[var.sub_resources_locations[each.key]]
# #   storage_account_id = var.default_storage_accounts[var.sub_resources_locations[count.index]]
# #   # storage_account_id = lookup(var.default_storage_accounts, each.value.location, null)
# #   # storage_account_id = lookup(var.aks_storage_accounts, each.value.location, var.default_storage_accounts[each.value.location])

#   dynamic "enabled_log" {
#     for_each = split(",", local.categorize[each.key])

#     content {
#       category = enabled_log.value

#       # retention_policy {
#       #   enabled = true
#       #   days    = 30
#       # }
#     }
#   }
# }

# resource "azurerm_monitor_diagnostic_setting" "audit_event" {
#   for_each = {
#     for i, r_id in [flatten([for i in local.sub_resource_ids : i])] : i => r_id
#   }

# #   # name               = "CyngularDiagnostic"
#   name               = "CyngularDiagnostic-${var.client_name}"
#   target_resource_id = each.value

#   storage_account_id = var.default_storage_accounts[local.sub_resource_ids[each.key]]
#   # storage_account_id = var.default_storage_accounts[var.sub_resources_locations[each.key]]
# #   # storage_account_id = lookup(var.default_storage_accounts, each.value.location, null)
# #   # storage_account_id = lookup(var.aks_storage_accounts, each.value.location, var.default_storage_accounts[each.value.location])

#   dynamic "enabled_log" {
#     for_each = split(",", local.categorize[each.key])

#     content {
#       category = enabled_log.value

#       # retention_policy {
#       #   enabled = true
#       #   days    = 30
#       # }
#     }
#   }
# }
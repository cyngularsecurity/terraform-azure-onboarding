locals {
  flattened_resources = flatten([
    for rg in var.sub_resource_group_names : [
      for resource in data.azurerm_resources.sub_resources[rg].resources : {
        id       = resource.id
        type     = resource.type
        location = resource.location
      }
    ]
  ])
  log_settings = {
    all_logs = [
      "Microsoft.Compute/components",
      "Microsoft.Compute/bastionHosts",
      # "Microsoft.Network/networkSecurityGroups",
    ],
    all_and_audit_logs = [
      "Microsoft.EventHub/namespaces",
      "Microsoft.DBforMySQL/flexibleServers",
      # "Microsoft.Sql/servers",
      # "Microsoft.KeyVault/vaults",
      # "Microsoft.Network/publicIPAddresses",
      # "Microsoft.OperationalInsights/workspaces",
    ],
    no_logs = [
      "Microsoft.Web/sites",
      "Microsoft.Web/serverFarms",
      "Microsoft.Compute/disks",
      "Microsoft.Compute/snapshots",
      "Microsoft.Compute/virtualMachines",
      "Microsoft.Compute/sshPublicKeys",
      "Microsoft.Network/networkWatchers",
      "Microsoft.Network/virtualNetworks",
      "Microsoft.Network/networkInterfaces",
      "Microsoft.Storage/storageAccounts",
    ]
  }
  resource_log_settings = merge(
    { for type in local.log_settings.all_logs : type => { categories = ["allLogs"], retention = 30 } },
    { for type in local.log_settings.all_and_audit_logs : type => { categories = ["allLogs", "audit"], retention = 30 } },
    { for type in local.log_settings.no_logs : type => null }
  )
}

data "azurerm_resources" "sub_resources" {
  for_each            = toset(var.sub_resource_group_names)
  resource_group_name = each.value
}

# resource "azurerm_monitor_diagnostic_setting" "activity_logs" {
#   for_each = { for i, resource in local.flattened_resources : i => resource }


#   name               = "CyngularDiagnostic"
#   target_resource_id = each.value.id
#   storage_account_id = lookup(var.default_storage_accounts, each.value.type, null)

#   dynamic "enabled_log" {
#     for_each = try(local.logs[each.value.type], [])

#     content {
#       category = log.value.category
#       enabled  = log.value.enabled
#       retention_policy {
#         enabled = try(log.value.retention_policy.enabled, false)
#         days    = try(log.value.retention_policy.days, 0)
#       }
#     }
#   }
# }

resource "azurerm_monitor_diagnostic_setting" "activity_logs" {
  name               = "CyngularDiagnostic"
  target_resource_id = "/subscriptions/${var.subscription}"
  storage_account_id = lookup(var.default_storage_accounts, keys(var.default_storage_accounts)[0], null)

  enabled_log { // ACTIVITY_LOGS
    category = "Recommendation"

    retention_policy {
      enabled = false
      days    = 30
    }
  }
  enabled_log {
    category = "Alert"

    retention_policy {
      enabled = false
      days    = 30
    }
  }
  enabled_log {
    category = "ServiceHealth"

    retention_policy {
      enabled = false
      days    = 30
    }
  }
  enabled_log {
    category = "Administrative"

    retention_policy {
      enabled = false
      days    = 30
    }
  }
  enabled_log {
    category = "Security"

    retention_policy {
      enabled = false
      days    = 30
    }
  }

  enabled_log {
    category = "Policy"

    retention_policy {
      enabled = false
      days    = 30
    }
  }
  enabled_log {
    category = "Autoscale"

    retention_policy {
      enabled = false
      days    = 30
    }
  }
  enabled_log {
    category = "ResourceHealth"

    retention_policy {
      enabled = false
      days    = 30
    }
  }
}
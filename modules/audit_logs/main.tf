resource "azurerm_monitor_aad_diagnostic_setting" "cyngular_audit_logs" {
  name               = local.aad_ds.name
  storage_account_id = var.default_storage_accounts[var.main_location]

  dynamic "enabled_log" {
    for_each = toset(local.aad_diagnostic_categories)
    content {
      category = enabled_log.value
    }
  }
}
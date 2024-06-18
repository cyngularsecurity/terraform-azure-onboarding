data "azurerm_subscription" "current" {}

# data "local_file" "policy_definition" {
#   filename = local.policy_json_path
# }

# data "azurerm_monitor_diagnostic_categories" "default" {
#   for_each    = var.diagnostic_settings
#   resource_id = each.value.target
# }

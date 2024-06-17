# locals {
#   policy_def_json  = jsondecode(data.local_file.policy_definition.content)
#   policy_json_path = "${path.module}/policy_def.json"

#   main_location = element(var.client_locations, 0)
# }

# # data "azurerm_subscription" "primary" {}
# data "local_file" "policy_definition" {
#   filename = local.policy_json_path
# }

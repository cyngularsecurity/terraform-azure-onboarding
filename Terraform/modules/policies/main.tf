locals {
  main_location = element(var.client_locations, 0)
  main_sub      = data.azurerm_subscription.current.id

  # policy_def_json  = jsondecode(data.local_file.policy_definition.content)
  # policy_json_path = "${path.module}/policy_def.json"
}
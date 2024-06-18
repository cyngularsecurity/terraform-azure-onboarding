locals {
  main_location = element(var.client_locations, 0)

  # policy_def_json  = jsondecode(data.local_file.policy_definition.content)
  # policy_json_path = "${path.module}/policy_def.json"
}
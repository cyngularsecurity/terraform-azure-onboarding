data "azuread_client_config" "current" {}

# data "local_file" "policy_definition" {
#   filename = local.policy_json_path
# }

# data "azurerm_monitor_diagnostic_categories" "default" {
#   for_each    = var.diagnostic_settings
#   resource_id = each.value.target
# }

# resource "null_resource" "unyamelize" {
#   triggers = {
#     yaml_file = "${file("${path.module}/policy_def.yaml")}"
#   }

#   provisioner "local-exec" {
#     interpreter = ["bash", "-c"]
#     command     = <<-EOT
#       yq eval -o=json ${path.module}/policy_def.yaml > ${path.module}/policy_def.json
#     EOT
#   }
# }
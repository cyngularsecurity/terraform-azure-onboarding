
output "org_admin_consent_url" {
  description = "Admin Consent URL"
  value       = "https://login.microsoftonline.com/organizations/adminconsent?client_id=${var.application_id}"
}

# output "deploy_script_path" {
#   value = module.cyngular_function.deploy_script_path
# }

# output "deploy_script_env" {
#   value = module.cyngular_function.deploy_script_env
# }

# output "sync_triggers_command" {
#   value = module.cyngular_function.sync_triggers_command
# }
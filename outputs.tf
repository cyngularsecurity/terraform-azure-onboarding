
output "org_admin_consent_url" {
  description = "Admin Consent URL"
  value       = "https://login.microsoftonline.com/organizations/adminconsent?client_id=${var.application_id}"
}

output "required_role" {
  value = [
    for assignment in data.azurerm_role_assignments.current_user.role_assignments :
    assignment.role_definition_name
  ]
  description = "List of role definition names assigned to the current user"
  depends_on  = []
}
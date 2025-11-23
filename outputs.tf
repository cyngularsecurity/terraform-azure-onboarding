
output "org_admin_consent_url" {
  description = "Admin Consent URL"
  value       = "https://login.microsoftonline.com/organizations/adminconsent?client_id=${var.application_id}"
}

# output "required_role" {
#   value = {
#     # Map of known role IDs to names for the roles we care about
#     role_ids = [
#       for assignment in data.azurerm_role_assignments.current_user.role_assignments :
#       assignment.role_definition_id
#     ]
#     role_names = [
#       for assignment in data.azurerm_role_assignments.current_user.role_assignments :
#       assignment.role_definition_id == data.azurerm_role_definition.owner.role_definition_id ? "Owner" :
#       assignment.role_definition_id == data.azurerm_role_definition.contributor.role_definition_id ? "Contributor" :
#       "Other (${basename(assignment.role_definition_id)})"
#     ]
#   }
#   description = "Role assignments for the current user on the management group"
#   depends_on  = []
# }
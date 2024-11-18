
output "org_admin_consent_url" {
  description = "Admin Consent URL"
  value = "######## admin consent url: https://login.microsoftonline.com/organizations/adminconsent?client_id=${var.application_id} #######"
}

output "root_mgmt_group_id" {
  value = data.azurerm_management_group.root.id
}
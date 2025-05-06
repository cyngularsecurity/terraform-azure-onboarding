
output "org_admin_consent_url" {
  description = "Admin Consent URL"
  value       = "https://login.microsoftonline.com/organizations/adminconsent?client_id=${var.application_id}"
}
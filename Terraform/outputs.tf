
# output "admin_consent_url" {
#   value = "######## admin consent url: https://login.microsoftonline.com/organizations/adminconsent?client_id=${var.application_id} #######"
# }

output "all_resource_groups" {
  value = flatten([for s in data.external.resource_groups : values(s.result)])
}

# output "all_resources" {
#   value = flatten([
#     for s in module.diagnostic_settings : [
#       for resource in s.all_resources : resource
#     ]
#   ])
# }

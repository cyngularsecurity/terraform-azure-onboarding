data "azuread_client_config" "current" {}
data "azuread_application_published_app_ids" "well_known" {}
data "azurerm_subscriptions" "available" {}

# data "archive_file" "audit_event_service_function" {
#   type        = "zip"
#   source_dir  = "../Services/audit_event/audit_event-service"
#   output_path = "zips/cyngular-audit_event-service.zip"
# }
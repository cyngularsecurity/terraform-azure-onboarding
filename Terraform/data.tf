data "azuread_client_config" "current" {}
data "azuread_application_published_app_ids" "well_known" {}
data "azurerm_subscriptions" "available" {}

data "archive_file" "cyngular_function" {
  type        = "zip"
  source_dir  = "../Services/activity_logs"
  output_path = "zips/cyngular-service.zip"
}
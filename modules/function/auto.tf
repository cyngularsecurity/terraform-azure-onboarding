
# resource "azurerm_automation_account" "a" {
#   name                = "tfex-example-account"
#   location            = azurerm_resource_group.example.location
#   resource_group_name = azurerm_resource_group.example.name
#   sku_name            = "Basic"
# }

# resource "azurerm_automation_runbook" "a" {
#   name                    = "RestartFunctionAppRunbook"
#   location                = azurerm_automation_account.a.location
#   resource_group_name     = azurerm_automation_account.a.resource_group_name
#   automation_account_name = azurerm_automation_account.a.name
#   log_verbose             = true
#   log_progress            = true
#   runbook_type            = "Python"
#   description             = "Runbook to restart Azure Function App"

# #   content                 = file("${path.root}/RunBooks/RestartFunc.sh")

#   content = data.local_file.restart_func.content
# #   publish_content_link {
# #     uri = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/c4935ffb69246a6058eb24f54640f53f69d3ac9f/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
# #   }
# }


# resource "azurerm_automation_schedule" "a" {
#   name                    = "MonthlyRestartSchedule"
#   resource_group_name     = azurerm_automation_account.a.resource_group_name
#   automation_account_name = azurerm_automation_account.a.name
#   frequency               = "Month"
#   interval                = 1
#   timezone                = "UTC"
#   start_time              = "2024-09-01T00:00:00Z"
# }

# resource "azurerm_automation_job_schedule" "a" {
#   automation_account_name = azurerm_automation_account.a.name
#   resource_group_name     = azurerm_automation_account.a.resource_group_name
#   runbook_name            = azurerm_automation_runbook.a.name
#   schedule_name           = azurerm_automation_schedule.a.name
# }


# # resource "azurerm_automation_variable_string" "subscription_id" {
# #   name                    = "AZURE_SUBSCRIPTION_ID"
# #   value                   = ""
# #   resource_group_name     = azurerm_automation_account.example.resource_group_name
# #   automation_account_name = azurerm_automation_account.example.name
# # }

# # resource "azurerm_automation_variable_string" "resource_group_name" {
# #   name                    = "RESOURCE_GROUP_NAME"
# #   value                   = ""
# #   resource_group_name     = azurerm_automation_account.example.resource_group_name
# #   automation_account_name = azurerm_automation_account.example.name
# # }

# # resource "azurerm_automation_variable_string" "function_app_name" {
# #   name                    = "FUNCTION_APP_NAME"
# #   value                   = ""
# #   resource_group_name     = azurerm_automation_account.example.resource_group_name
# #   automation_account_name = azurerm_automation_account.example.name
# # }

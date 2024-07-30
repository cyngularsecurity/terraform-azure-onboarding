output "client_rg" {
  description = "regional resource group to put all client resources in"
  value       = azurerm_resource_group.cyngular_client.name
}

output "sp_id" {
  value     = azuread_service_principal.client_sp.id
  sensitive = true
}

# output "storage_accounts_ids" {
#   value = { for k, sa in azurerm_storage_account.cyngular_sa : sa.location => sa.id }
#   # value = { for k, sa in azurerm_storage_account.cyngular_sa : k => sa.id }
# }

output "storage_accounts_ids" {
  value = { for k, sa in azurerm_storage_account.cyngular_sa : sa.location => sa.id }
}
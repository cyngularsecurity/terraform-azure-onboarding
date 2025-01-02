output "client_rg" {
  description = "regional resource group to put all client resources in"
  value       = azurerm_resource_group.cyngular_client
}

output "sp_id" {
  value     = azuread_service_principal.client_sp.object_id 
  sensitive = true
}

output "storage_accounts_ids" {
  value = { for k, sa in azurerm_storage_account.cyngular_sa : sa.location => sa.id }
}
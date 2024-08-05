

resource "azurerm_storage_account" "cyngular_sa" {
  for_each = toset(var.locations)

  # name                = lower(substr("cyngular${var.client_name}${each.key}", 0, 24))
  name                = lower(substr("${var.client_name}sa${each.key}", 0, 23))
  resource_group_name = azurerm_resource_group.cyngular_client.name
  location            = each.value

  account_kind = "StorageV2"
  account_tier = "Standard"

  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = merge(local.storage_acount_tags, var.tags)
}

resource "azurerm_role_assignment" "sa_contributor" {
  for_each             = azurerm_storage_account.cyngular_sa
  scope                = each.value.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azuread_service_principal.client_sp.id
}

resource "azurerm_role_assignment" "blob_contributor" {
  for_each             = azurerm_storage_account.cyngular_sa
  scope                = each.value.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azuread_service_principal.client_sp.id
}
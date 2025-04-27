resource "azurerm_storage_account" "cyngular_sa" {
  for_each = toset(var.locations)
  name     = lower(substr("cyngular${each.key}${var.suffix}", 0, 23))

  resource_group_name = azurerm_resource_group.cyngular_client.name
  location            = each.value

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  # allow_nested_items_to_be_public        = false
  # default_to_oauth_authentication         = false
  # infrastructure_encryption_enabled   = true 

  # blob_properties {
  #   delete_retention_policy {
  #     days                     = 100
  #     permanent_delete_enabled = true
  #   }
  #   container_delete_retention_policy {
  #     days = 7
  #   }
  # }

  tags = merge( 
    each.key == var.main_location ? local.main_storage_account_tags : local.common_storage_account_tags,
    var.tags
  )
}

resource "azurerm_role_assignment" "sa_contributor" {
  for_each             = azurerm_storage_account.cyngular_sa
  scope                = each.value.id

  role_definition_name = "Storage Account Contributor"
  principal_id         = azuread_service_principal.client_sp.object_id
}

resource "azurerm_role_assignment" "blob_contributor" {
  for_each             = azurerm_storage_account.cyngular_sa
  scope                = each.value.id

  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azuread_service_principal.client_sp.object_id
}
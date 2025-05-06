resource "azurerm_user_assigned_identity" "function_assignment_identity" {
  name = format("%s-mgmt-uai", var.client_name)

  location            = var.main_location
  resource_group_name = var.cyngular_rg_name
}

resource "azurerm_role_definition" "function_assignment_def" {
  scope = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"

  name        = format("%s-cyngular-mgmt-role", var.client_name)
  description = "cyngular uai mgmt role"

  permissions {
    actions = [
      "Microsoft.Resources/deployments/*",
      "Microsoft.Insights/diagnosticSettings/read",
      "Microsoft.Insights/diagnosticSettings/write",

      "Microsoft.Network/networkWatchers/flowLogs/write",
      "Microsoft.Network/networkWatchers/write",
      "Microsoft.Network/networkSecurityGroups/write",

      "Microsoft.Network/virtualNetworks/write"
    ]
  }

  assignable_scopes = ["/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"]
}

resource "azurerm_role_assignment" "func_assigment_custom_mgmt" {
  scope = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"

  principal_id       = azurerm_user_assigned_identity.function_assignment_identity.principal_id
  role_definition_id = azurerm_role_definition.function_assignment_def.role_definition_resource_id
}

resource "azurerm_role_assignment" "func_assigment_reader_mgmt" {
  scope = "/providers/Microsoft.Management/managementGroups/${local.mgmt_group_id}"

  principal_id         = azurerm_user_assigned_identity.function_assignment_identity.principal_id
  role_definition_name = "Reader"
}

resource "azurerm_role_assignment" "sa_contributor" {
  for_each = merge(var.default_storage_accounts, { app = azurerm_storage_account.func_storage_account.id })
  scope    = each.value

  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.function_assignment_identity.principal_id
}

resource "azurerm_role_assignment" "blob_contributor" {
  for_each = merge(var.default_storage_accounts, { app = azurerm_storage_account.func_storage_account.id })
  scope    = each.value

  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.function_assignment_identity.principal_id
}
resource "azuread_service_principal" "msgraph" {
  client_id    = var.msgraph_id
  use_existing = true
}

resource "azuread_service_principal" "client_sp" {
  client_id = var.application_id
  owners    = [var.current_user_obj_id]
}

resource "azuread_service_principal_delegated_permission_grant" "admin" {
  service_principal_object_id          = azuread_service_principal.client_sp.object_id
  resource_service_principal_object_id = azuread_service_principal.msgraph.object_id
  claim_values                         = ["Directory.Read.All", "Group.Read.All", "User.Read.All", "AuditLog.Read.All", "UserAuthenticationMethod.Read.All"]
}
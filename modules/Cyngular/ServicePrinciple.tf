resource "azuread_service_principal" "msgraph" {
  client_id    = var.msgraph_id
  use_existing = true
}

resource "azuread_service_principal" "client_sp" {
  client_id = var.application_id
  owners    = [var.current_user_obj_id]
}
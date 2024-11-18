
resource "azurerm_resource_group" "cyngular_client" {
  name     = format("%s-rg", var.prefix)
  location = var.main_location

  tags = var.tags
}
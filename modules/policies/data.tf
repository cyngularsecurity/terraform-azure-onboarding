data "azuread_client_config" "current" {}

# resource "random_string" "suffix" {
#   length  = 4
#   special = false
#   upper   = false

#   # override_special = "/@£$"
# }
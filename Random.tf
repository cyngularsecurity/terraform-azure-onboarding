## Randomize name for function app & storage account
resource "random_string" "suffix" {
  length  = 7
  numeric = true
  special = false
  upper   = false
}
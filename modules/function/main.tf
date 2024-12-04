resource "random_string" "suffix" {
  length  = 5
  numeric = true
  special = false
  upper   = false
}
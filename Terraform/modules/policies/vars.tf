variable "client_name" {
  description = "Company name"
  type        = string
}
variable "subscriptions" {
  description = "list of sub IDs"
  type        = list(string)
}
variable "client_locations" {
  description = "List of locations the client operates in"
  type        = list(string)
}
variable "main_location" {
  type        = string
  description = "client main location"
}
variable "cyngular_rg_name" {
  type        = string
  description = "cyngular rg on the client side"
}
variable "prefix" {
  description = "Prefix to include in resource names"
  type        = string
}
variable "tags" {
  type        = map(string)
  description = "A map of the tags to use for the resources that are deployed."
}
variable "default_storage_accounts" {
  description = "Map of default storage accounts by location"
  type        = map(string)
}
# variable "sub_resource_group_names" {
#   description = "Name list of resource groups in the sub"
#   type        = list(string)
# }

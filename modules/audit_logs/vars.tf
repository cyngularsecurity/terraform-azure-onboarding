
variable "client_name" {
  type        = string
  description = "name of the client"
}

variable "subscription_ids" {
  description = "subs names and ids"
  type        = map(string)
}

variable "locations" {
  description = "List of locations to create storage accounts"
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

variable "tags" {
  type        = map(string)
  description = "A map of the tags to use for the resources that are deployed."
}

variable "suffix" {
  description = "Suffix to include in resource names"
  type        = string
}

variable "default_storage_accounts" {
  description = "Map of default storage accounts by location"
  type        = map(string)
}
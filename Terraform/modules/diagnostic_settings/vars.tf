variable "client_name" {
  description = "Company name"
  type        = string
}

variable "subscription" {
  description = "the sub ID"
  type        = string
}

variable "client_locations" {
  description = "List of locations the client operates in"
  type        = list(string)
}

variable "sub_resource_group_names" {
  description = "Name list of resource groups in the sub"
  type        = list(string)
}

variable "default_storage_accounts" {
  description = "Map of default storage accounts by location"
  type        = map(string)
}

# variable "network_security_group_storage_accounts" {
#   description = "Map of storage accounts for network security groups by location"
# type        = map(string)
#   default = {}
# }

# variable "storage_accounts_storage_accounts" {
#   description = "Map of storage accounts for storage accounts by location"
# type        = map(string)
#   default = {}
# }

# variable "sql_servers_storage_accounts" {
#   description = "Map of storage accounts for SQL servers by location"
# type        = map(string)
#   default = {}
# }
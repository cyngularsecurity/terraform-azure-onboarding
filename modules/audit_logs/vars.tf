
variable "client_name" {
  type        = string
  description = "name of the client"
}

variable "main_location" {
  type        = string
  description = "client main location"
}

variable "default_storage_accounts" {
  description = "Map of default storage accounts by location"
  type        = map(string)
}
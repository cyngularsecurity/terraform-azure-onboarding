
variable "subscriptions" {
  description = "List of subscription IDs"
  type        = list(string)
}

variable "role_name" {
  description = "Azure built-in role name to assign"
  type        = string
}

variable "service_principal_id" {
  description = "Service Principal ID to which roles will be assigned"
  type        = string
}
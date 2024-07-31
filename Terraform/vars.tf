variable "client_name" {
  description = "Company name"
  type        = string
}

variable "tenant_id" {
  description = "Tenant ID to fetch all subscriptions"
  type        = string
}

variable "application_id" {
  description = "Application ID for the multi-tenant service principal"
  type        = string
}

variable "locations" {
  description = "List of locations to create storage accounts"
  type        = list(string)
}

variable "tags" {
  type        = map(string)
  description = "A map of the tags to use for the resources that are deployed."
}

variable "roles_json" {
  description = "JSON list of roles to assign"
  type        = string
}
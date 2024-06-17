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

variable "enable_audit_events_logs" {
  description = "create diagnostic settings for audit events - on resources scope"
  type        = bool
  default     = true
}

variable "enable_activity_logs" {
  description = "create diagnostic settings for activity logs - on sub scope"
  type        = bool
  default     = true
}

# variable "sub_resources_ids" {
#   description = "ids of sub scope resources"
#   type        = list(string)
# }
# variable "sub_resources_locations" {
#   description = "locations of sub scope resources"
#   type        = list(string)
# }
# variable "sub_resources_types" {
#   description = "types of sub scope resources"
#   type        = list(string)
# }

variable "client_name" {
  type        = string
  description = "name of the client"
}
variable "subscription_ids" {
  description = "subs names and ids"
  type        = map(string)
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
variable "tags" {
  type        = map(string)
  description = "A map of the tags to use for the resources that are deployed."
}

variable "default_storage_accounts" {
  description = "Map of default storage accounts by location"
  type        = map(string)
}

variable "enable_activity_logs" {
  description = "create diagnostic settings for activity logs - on sub scope"
  type        = bool
  default     = true
}

variable "enable_audit_events_logs" {
  description = "create diagnostic settings for audit events - on resources scope"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "config flow logs for nsgs without - on nsgs scope"
  type        = bool
  default     = true
}

variable "enable_aks_logs" {
  description = "config aks logs for aks clusters - on cluster scope"
  type        = bool
  default     = true
}

# variable "black_listed_types" {
#   description = "List of resource types to exclude from evaluation"
#   type        = list(string)
#   default     = []
# }

# variable "type_list_a" {
#   description = "List of resource types to check for AllLogs category"
#   type        = list(string)
#   default     = ["Microsoft.Compute/virtualMachines"]
# }

# variable "type_list_b" {
#   description = "List of resource types to check for AllLogs and Audit categories"
#   type        = list(string)
#   default     = ["Microsoft.Network/networkSecurityGroups"]
# }

# variable "subscription_names" {
#   description = "subs names and ids"
#   type        = map(string)
# }

variable "os" {
  type        = string
  description = "the os of the client pc"
}
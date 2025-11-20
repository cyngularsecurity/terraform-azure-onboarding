variable "client_name" {
  type        = string
  description = "name of the client"
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
  description = "cyngular rg name on the client side"
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

variable "enable_activity_logs" {
  description = "create diagnostic settings for activity logs - on sub scope"
  type        = bool
}

variable "enable_audit_events_logs" {
  description = "create diagnostic settings for audit events - on resources scope"
  type        = bool
}

variable "enable_flow_logs" {
  description = "config flow logs for nsgs without - on nsgs scope"
  type        = bool
}

variable "enable_aks_logs" {
  description = "config aks logs for aks clusters - on cluster scope"
  type        = bool
}

# variable "app_insights_unsupported_locations" {
#   type        = list(string)
#   description = "list of locations that are not supported for app insights"
#   default     = ["israelcentral"]
# }

variable "allow_function_logging" {
  description = "allow function logging"
  type        = bool
}

variable "mgmt_group_id" {
  description = "management group root id"
  type        = string
}

variable "creator_local_ip" {
  description = "creator local ip"
  type        = string
}

variable "caching_enabled" {
  description = "enable caching"
  type        = bool
}

variable "use_cli_deployment" {
  description = "Use Azure CLI for deployment instead of zip_deploy_file (recommended for Flex Consumption)"
  type        = bool
  default     = true
}
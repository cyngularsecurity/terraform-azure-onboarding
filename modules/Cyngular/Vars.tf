
variable "locations" {
  description = "List of locations to create storage accounts"
  type        = list(string)
}

variable "main_location" {
  type        = string
  description = "client main location"
}

variable "client_name" {
  type        = string
  description = "name of the client"
}

variable "tags" {
  type        = map(string)
  description = "A map of the tags to use for the resources that are deployed."
}

variable "application_id" {
  description = "Application ID for the multi-tenant service principal"
  type        = string
}

variable "prefix" {
  description = "Prefix to include in resource names"
  type        = string
}

variable "suffix" {
  description = "Suffix to include in resource names"
  type        = string
}

variable "msgraph_id" {
  description = "microsoft graph enterprise application id"
  type        = string
}

variable "current_user_obj_id" {
  description = "configuration object id of current user"
  type        = string
}

variable "enable_audit_logs" {
  description = "create diagnostic settings for audit logs - on active directory scope"
  type        = bool
  default     = true
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

variable "override_location" {
  type        = string
  description = "supported location for function related resources"
  default = ""
}
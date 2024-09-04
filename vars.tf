variable "client_name" {
  description = "Company name"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.client_name))
    error_message = "Company name must contain only lowercase letters and digits."
  }
}
variable "application_id" {
  description = "Application ID for the multi-tenant service principal"
  type        = string
  nullable = false
}
variable "locations" {
  description = "List of locations to create storage accounts"
  type        = list(string)
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

variable "os" {
  type        = string
  description = "the os of the client pc"
  default = "linux"
}
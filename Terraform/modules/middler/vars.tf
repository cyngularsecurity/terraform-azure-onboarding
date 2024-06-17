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

variable "enable_flow_logs" {
  description = "config flow logs for nsgs without - on nsgs scope"
  type        = bool
  default     = true
}

variable "client_name" {
  description = "Company name"
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
variable "enable_aks_logs" {
  description = "config aks logs for aks clusters - on cluster scope"
  type        = bool
  default     = true
}
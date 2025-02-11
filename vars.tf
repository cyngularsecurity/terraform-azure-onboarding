variable "client_name" {
  description = "Company name"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.client_name))
    error_message = "Company name must contain only lowercase letters and digits."
  }
}

variable "main_subscription_id" {
  description = "the clientt main subscription id, for azure resource manager provider auth"
  type        = string
  nullable    = false
}

variable "application_id" {
  description = "Application Client ID for the multi-tenant service principal"
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$", var.application_id))
    error_message = "The value must be a valid UUID."
  }
}

variable "locations" {
  description = "List of locations that the clients operate in"
  type        = list(string)
  
  # validation {
  #   condition     = !(length(var.locations) == 1 && contains(var.locations, "israelcentral"))
  #   error_message = "The list of locations cannot contain only 'israelcentral', as it is not supported for consumption plan deployment. Please add more locations or choose a different location."
  # }
}

variable "main_location" {
  type        = string
  description = "The Main location for Storage Account deployment, main sa will contain Audit & Activity logs"
  default     = ""

  # validation {
  #   condition     = contains(var.locations, var.main_location)
  #   error_message = "The main location must be one of the specified locations in the locations variable."
  # }
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

variable "local_os" {
  type        = string
  description = "the os of the client pc"
  default     = "linux"
}
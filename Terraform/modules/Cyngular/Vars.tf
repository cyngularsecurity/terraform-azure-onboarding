
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

variable "msgraph_id" {
  description = "microsoft graph enterprise application id"
  type        = string
}

variable "current_user_obj_id" {
  description = "configuration object id of current user"
  type        = string
}


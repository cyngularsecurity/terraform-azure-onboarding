
variable "client_name" {
  type        = string
  description = "name of the client"
}
variable "tags" {
  type        = map(string)
  description = "A map of the tags to use for the resources that are deployed."
}
variable "cyngular_rg_name" {
  description = "the resource group name for cyngular rg"
}
variable "func_name" {
  type        = string
  description = "name of the service"
}
variable "service_plan_id" {
  type        = string
  description = "the id of the service plan"
}
variable "service_zip" {
  type        = string
  description = "local zip of function"
}
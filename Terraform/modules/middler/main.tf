locals {
  # resource_prefix = format("cyngular-%s", var.client_name)
  sub_resource_groups = [
    for rg in values(data.external.resource_groups.result) : rg
  ]
}
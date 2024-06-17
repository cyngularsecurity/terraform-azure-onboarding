
output "resource_ids" {
  value = [flatten(local.sub_resource_ids)]
}

output "resource_locations" {
  value = [flatten(local.sub_resource_locations)]
}

output "sub_resource_ids" {
  value = {
  for id, type in [flatten([local.sub_resource_ids])] : id => type }
}

output "categorize" {
  value = local.categorize
}
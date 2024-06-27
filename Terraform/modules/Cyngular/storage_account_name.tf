# locals {
#   max_length = 24
#     static_prefix = "cyngular"
#     max_client_length = local.max_length - length(local.static_prefix) - length(var.region)

#   # Truncate and format the client name to fit within the limits
#   truncated_client_name = substr(lower(var.client_name), 0, local.max_client_length)
#     storage_account_name = format("%s%s%s", local.static_prefix, local.truncated_client_name, lower(var.region))
# }

# locals {
#   client_name_short = substr(var.client_name, 0, 10)
#   location_short    = substr(each.key, 0, 10)
#   name_base         = "cyngular${local.client_name_short}${local.location_short}"
#   unique_suffix     = substr(md5(local.name_base), 0, 4) // Add a 4-character hash suffix for uniqueness
#   final_name        = lower(substr("${local.name_base}${local.unique_suffix}", 0, 24))
# }
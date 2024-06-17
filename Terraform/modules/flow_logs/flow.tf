# resource "null_resource" "check_flow_logs" {
#   for_each = toset(var.sub_resource_group_names)

#   provisioner "local-exec" {
#     interpreter = ["bash", "-c"]
#     on_failure = fail

#     environment = {
#       subscription_id  = var.subscription
#       resource_group   = each.value
#       client_locations = join(",", var.client_locations)
#     }

#     command = <<EOT
#       set -e

#       SUBSCRIPTION_ID=$subscription_id
#       CLIENT_LOCATIONS=$client_locations
#       RESOURCE_GROUP=$resource_group
#       IFS=',' read -r -a locations <<< "$CLIENT_LOCATIONS"

#       nsgs_not_logging=()

#       for location in "$\{locations[@]\}"; do
#         nsgs=$(az network nsg list --subscription "$SUBSCRIPTION_ID" --resource-group "$RESOURCE_GROUP" --location "$location" --query "[].{Name:name}" -o json)

#         for nsg in $(echo "$nsgs" | jq -c '.[]'); do
#           nsg_name=$(echo "$nsg" | jq -r '.Name')

#           is_logging=$(az network watcher flow-log show --subscription "$SUBSCRIPTION_ID" --location "$location" --nsg-name "$nsg_name" --query "enabled" -o tsv || echo "false")
#           if [ "$is_logging" != "true" ]; then
#             nsgs_not_logging+=("$nsg_name")
#           fi
#         done
#       done

#       jq -n --argjson nsgs "$(printf '%s\n' "$\{nsgs_not_logging[@]\}" | jq -R . | jq -s .)" \
#         '{nsgs_not_logging: $nsgs}' > ${path.module}/flow_log_output.json
#     EOT
#   }
#   triggers = {
#     sub_resource_group_names = join(",", var.sub_resource_group_names)
#   }
# }

# # Save the output of the script to a local file
# resource "local_file" "flow_log_output" {
#   depends_on = [null_resource.check_flow_logs]
#   content    = file("${path.module}/flow_log_output.json")
#   filename   = "${path.module}/flow_log_output.json"
# }

# # Read the output from the local file
# data "local_file" "flow_log_output" {
#   depends_on = [local_file.flow_log_output]
#   filename   = "${path.module}/flow_log_output.json"
# }
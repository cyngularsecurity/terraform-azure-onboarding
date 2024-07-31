#!/usr/bin/env bash
set -e

# Read subscription ID and client locations from the input
eval "$(jq -r '@sh "SUBSCRIPTION_ID=\(.subscription_id) CLIENT_LOCATIONS=\(.client_locations)"')"

# Convert the comma-separated locations string to an array
IFS=',' read -r -a locations <<< "$CLIENT_LOCATIONS"
az account set --subscription "$SUBSCRIPTION_ID"
filtered_resource_groups=()

for location in "${locations[@]}"; do
  location_resource_groups=$(az group list --subscription "$SUBSCRIPTION_ID" --query "[?location=='$location'].name" -o json)
    for rg in $(echo "$location_resource_groups" | jq -r '.[]'); do
    filtered_resource_groups+=("$rg")
  done
done

# Convert the array of resource group names to a JSON array
resource_groups_json=$(printf '%s\n' "${filtered_resource_groups[@]}" | jq -R . | jq -s .)

# Map indexes to resource group names
jq -n --argjson resource_groups "$resource_groups_json" '
  reduce range(0; $resource_groups | length) as $i (
    {}; .[$i|tostring] = $resource_groups[$i]
  )'

#!/usr/bin/env bash
set -e

handle_error() {
  local exit_code=$?
  local line_no=$1
  local error_msg=$2

  jq -n --arg error "Error on line $line_no: $error_msg (exit code $exit_code)" '{"error": $error}'
  exit $exit_code
}

trap 'handle_error $LINENO "$BASH_COMMAND"' ERR
eval "$(jq -r '@sh "SUBSCRIPTION_ID=\(.subscription_id) CLIENT_LOCATIONS=\(.client_locations)"')"
IFS=',' read -r -a locations <<< "$CLIENT_LOCATIONS"
# az account set --subscription "$SUBSCRIPTION_ID"

filtered_resource_groups=()
error_message=""
for location in "${locations[@]}"; do
  location_resource_groups=$(az group list --subscription "$SUBSCRIPTION_ID" --query "[?location=='$location'].name" -o json 2>&1) || {
    error_message="$location_resource_groups"
    break
  }
  for rg in $(echo "$location_resource_groups" | jq -r '.[]'); do
    filtered_resource_groups+=("$rg")
  done
done

# If an error occurred, output an error message; otherwise, output the resource groups
if [ -n "$error_message" ]; then
  jq -n --arg error "$error_message" '{"error": $error}'
else
  resource_groups_json=$(printf '%s\n' "${filtered_resource_groups[@]}" | jq -R . | jq -s .)
  jq -n --argjson resource_groups "$resource_groups_json" '
    reduce range(0; $resource_groups | length) as $i (
      {}; .[$i|tostring] = $resource_groups[$i]
    )'
fi
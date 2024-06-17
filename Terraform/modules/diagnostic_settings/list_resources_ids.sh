#!/usr/bin/env bash
set -e

handle_error() {
  local exit_code=$?
  local line_no=$1
  local error_msg=$2

  jq -n --arg error "Error on line $line_no: $error_msg (exit code $exit_code)" '{"error": $error}'
  exit $exit_code
}; trap 'handle_error $LINENO "$BASH_COMMAND"' ERR

eval "$(jq -r '@sh "SUBSCRIPTION_ID=\(.subscription_id) CLIENT_LOCATIONS=\(.client_locations) RESOURCE_GROUP=\(.resource_group) EXCLUDED_TYPES=\(.excluded_types)"')"
IFS=',' read -r -a locations <<< "$CLIENT_LOCATIONS"
IFS=',' read -r -a excluded_types <<< "$EXCLUDED_TYPES"

filtered_resources=()
for location in "${locations[@]}"; do
  location_resources=$(az resource list --subscription "$SUBSCRIPTION_ID" --resource-group "$RESOURCE_GROUP" --location "$location" --query "[].{id:id,type:type}" -o json 2>&1) || continue

  if [ "$(echo "$location_resources" | jq -r '. | length')" -gt 0 ]; then
    for resource in $(echo "$location_resources" | jq -c '.[]'); do
      resource_id=$(echo "$resource" | jq -r '.id')
      resource_type=$(echo "$resource" | jq -r '.type')

      exclude=false
      for excluded_type in "${excluded_types[@]}"; do
        if [[ "${resource_type,,}" == "${excluded_type,,}" || "${resource_type,,}" == *"${excluded_type,,}"* ]]; then
          exclude=true
          break
        fi
      done

      if [[ "$exclude" == false ]]; then
        filtered_resources+=("$resource_id")
      fi
    done
  fi
done

resources_json=$(printf '%s\n' "${filtered_resources[@]}" | jq -R . | jq -s 'map(select(length > 0))')
jq -n --argjson resource_groups "$resources_json" '
  reduce range(0; $resource_groups | length) as $i (
    {}; .[$i|tostring] = $resource_groups[$i]
  )'

#!/usr/bin/env bash
set -e

eval "$(jq -r '@sh "SUBSCRIPTION_ID=\(.subscription_id) CLIENT_LOCATIONS=\(.client_locations) RESOURCE_GROUP=\(.resource_group) EXCLUDE_CYNGULAR=\(.exclude_cyngular)"')"
IFS=',' read -r -a locations <<< "$CLIENT_LOCATIONS"

fetch_deny_assignments() {
  token=$(az account get-access-token --query accessToken -o tsv)
  deny_assignments_url="https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Authorization/denyAssignments?api-version=2018-07-01"

  response=$(curl -s -H "Authorization: Bearer $token" "$deny_assignments_url")
  if [[ -z "$response" ]]; then
    exit 1
  fi

  # filters deny assignments to include:
  # specified resource group scoped.
  # Include actions or data actions that cover all actions (*) or specifically the Microsoft.Network/networkSecurityGroups/write action.
  # Do not explicitly exclude the Microsoft.Network/networkSecurityGroups/write action in notActions or notDataActions.
  echo "$response" | jq -r --arg resource_group_name "$RESOURCE_GROUP" '
    .value[] |
    select(.properties.scope | contains("/resourceGroups/" + $resource_group_name)) |
    select(
      (.properties.permissions[].actions[] == "*" or .properties.permissions[].actions[] == "Microsoft.Network/networkSecurityGroups/write")
      and (.properties.permissions[].notActions | index("Microsoft.Network/networkSecurityGroups/write") | not)
      and (.properties.permissions[].dataActions[] == "*" or .properties.permissions[].dataActions[] == "Microsoft.Network/networkSecurityGroups/write")
      and (.properties.permissions[].notDataActions | index("Microsoft.Network/networkSecurityGroups/write") | not)
    ) |
    .properties.scope'
}; deny_assignment_scopes=$(fetch_deny_assignments)

nsgs_without_flow_logs=()
for location in "${locations[@]}"; do
  nsg_output=$(az network nsg list --subscription "$SUBSCRIPTION_ID" --resource-group "$RESOURCE_GROUP" --query "[?location=='$location']" -o json)
  sleep 3
  flow_log_output=$(az network watcher flow-log list --subscription "$SUBSCRIPTION_ID" -l "$location" -o json)
  sleep 3

  nsgs=$(echo "$nsg_output" | jq -c '. // []')
  # flow_logs=$(echo "$flow_log_output" | jq -c '. // []')
  if [[ -z "$nsgs" ]]; then
    continue
  fi

  flow_log_nsg_ids=$(echo "$flow_log_output" | jq -r '.[].targetResourceId')
  excluded_flow_log_nsg_ids=$(echo "$flow_log_output" | jq -r --arg pattern "$EXCLUDE_CYNGULAR" '
    .[] | select(.name | test($pattern)) | .targetResourceId')

  # flow_log_nsg_ids=$(echo "$flow_logs" | jq -r '.[].targetResourceId // empty' | sort | uniq || echo "")
  # excluded_flow_log_nsg_ids=$(echo "$flow_logs" | jq -r --arg pattern "$EXCLUDE_CYNGULAR" '
  #   map(select(.name | test($pattern))) | .[].targetResourceId // empty' | sort | uniq || echo "")

  for nsg in $(echo "$nsgs" | jq -r '.[] | @base64'); do
    nsg_id=$(echo "$nsg" | base64 --decode | jq -r '.id')
    nsg_name=$(echo "$nsg" | base64 --decode | jq -r '.name')

    if [[ " $flow_log_nsg_ids " == *"$nsg_id"* ]] && [[ " $excluded_flow_log_nsg_ids " != *"$nsg_id"* ]]; then
      continue
    fi


    # if echo "$flow_log_nsg_ids" | grep -q "$nsg_id"; then
    #   if ! echo "$excluded_flow_log_nsg_ids" | grep -q "$nsg_id"; then
    #     continue
    #   fi
    # fi

    deny_assignment_match=false
    for deny_scope in $deny_assignment_scopes; do
      if [[ "${nsg_id,,}" == *"${deny_scope,,}"* ]]; then
        deny_assignment_match=true
        break
      fi
    done

    if ! $deny_assignment_match; then
      nsgs_without_flow_logs+=("{\"nsg_name\": \"$nsg_name\", \"location\": \"$location\"}")
    fi
  done
done

nsgs_json=$(printf '%s\n' "${nsgs_without_flow_logs[@]}" | jq -s 'map(select(length > 0))')
jq -n --argjson nsgs "$nsgs_json" '
  $nsgs | reduce .[] as $item (
    {}; .[$item.nsg_name] = $item.location
  )'
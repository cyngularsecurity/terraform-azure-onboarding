#!/usr/bin/env bash
set -e

eval "$(jq -r '@sh "SUBSCRIPTION_ID=\(.subscription_id) CLIENT_LOCATIONS=\(.client_locations)"')"
IFS=',' read -r -a locations <<< "$CLIENT_LOCATIONS"

nw_output=$(az network watcher list --subscription "$SUBSCRIPTION_ID" -o json)
nw_map=()

for location in "${locations[@]}"; do
  # nw_info=$(echo "$nw_output" | jq -r --arg location "$location" '.[] | select(.location == $location) | {id: .id, name: .name, resourceGroup: .resourceGroup}')
  nw_info=$(echo "$nw_output" | jq -r --arg location "$location" '[.[] | select(.location == $location)] | first')
  if [ -n "$nw_info" ] && [ "$nw_info" != "null" ]; then
    nw_id=$(echo "$nw_info" | jq -r '.id')
    nw_map+=("{\"$location\": \"$nw_id\"}")
  else
    nw_map+=("{\"$location\": \"\"}")
  fi
done

nw_json=$(printf '%s\n' "${nw_map[@]}" | jq -s 'map(select(length > 0)) | add')
jq -n --argjson nws "$nw_json" '$nws'
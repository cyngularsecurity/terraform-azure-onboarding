#!/usr/bin/env bash
set -e

eval "$(jq -r '@sh "SUBSCRIPTION_ID=\(.subscription_id)"')"
az account set --subscription "$SUBSCRIPTION_ID"
resource_groups=$(az group list --subscription "$SUBSCRIPTION_ID" --query '[].name' -o json)

# Map indexes to resource group names
jq -n --argjson resource_groups "$resource_groups" '
  reduce range(0; $resource_groups | length) as $i (
    {}; .[$i|tostring] = $resource_groups[$i]
  )'
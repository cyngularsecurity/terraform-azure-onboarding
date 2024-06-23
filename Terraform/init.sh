#!/usr/bin/env bash
set -eu

CLIENT_NAME=""

cp example.tfvars "${CLIENT_NAME}_on_boarding.tfvars"
terraform apply --auto-approve --var-file "${CLIENT_NAME}_on_boarding.tfvars" --target module.middler
terraform apply --auto-approve --var-file "${CLIENT_NAME}_on_boarding.tfvars"


# ------

terraform plan -out plan.out --var-file example.tfvars
terraform show -json > plan.json
docker run --rm -it -p 9000:9000 -v $(pwd)/plan.json:/src/plan.json im2nguyen/rover:latest -planJSONPath=plan.json


# --------

az login --output none

subscriptions=$(az account list --query "[].id" -o tsv)
output="{\"subscriptions\":["

# Loop through subscriptions to get management group
for subscription in $subscriptions; do
  mgmt_group=$(az account management-group subscription show --subscription $subscription --query "name" -o tsv)
  output+="{\"subscription_id\":\"$subscription\", \"management_group_name\":\"$mgmt_group\"},"
done

# Remove trailing comma and close JSON array
output=${output%,}
output+="]}"

# Output JSON
echo $output

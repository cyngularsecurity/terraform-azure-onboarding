#!/usr/bin/env bash
set -eu

CLIENT_NAME=""

cp example.tfvars "${CLIENT_NAME}_on_boarding.tfvars"
terraform apply --auto-approve --var-file "${CLIENT_NAME}_on_boarding.tfvars" --target module.middler
terraform apply --auto-approve --var-file "${CLIENT_NAME}_on_boarding.tfvars"

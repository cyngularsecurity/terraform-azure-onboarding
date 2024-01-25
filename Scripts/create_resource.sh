#!/usr/bin/env bash
set -eu

# Arguments
RESOURCE_GROUP="$1"
RESOURCE_TYPE="$2"
RESOURCE_NAME="$3"

# Create Resource
az resource create --resource-group "$RESOURCE_GROUP" \
  --resource-type "$RESOURCE_TYPE" --name "$RESOURCE_NAME"
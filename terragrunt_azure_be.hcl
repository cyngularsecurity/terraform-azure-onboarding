include {
  path = find_in_parent_folders()
}

# Inputs overridden by config
inputs = {
  region = local.region
  env    = local.env
  tags   = local.common_tags
}

locals {
  # # Parse the file path for environment/region/project information
  # path_parts = compact(split("/", path_relative_to_include()))
  # env        = local.path_parts[0]
  # region     = local.path_parts[1]
  # project    = local.path_parts[2]

  # Common tags
  common_tags = {
    Environment = local.env
    # Project     = local.project
    ManagedBy   = "Terragrunt"
  }
}

# Generate remote state configuration for child modules
remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    subscription_id      = get_env("ARM_SUBSCRIPTION_ID")
    tenant_id            = get_env("ARM_TENANT_ID")
    use_azuread_auth     = true

    resource_group_name  = "${local.env}-terraform-state-rg"
    storage_account_name = "${lower(local.env)}tfstate${random_string.suffix.result}"
    container_name       = "tfstate"

    key                  = "${local.region}/${local.project}/${path_relative_to_include()}/terraform.tfstate"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "azurerm" {
  features {}
  subscription_id = "${get_env("ARM_SUBSCRIPTION_ID")}"
  tenant_id       = "${get_env("ARM_TENANT_ID")}"
}
EOF
}

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}
EOF
}

# Create the resource group and storage account if they don't exist
generate "backend_resources" {
  path      = "backend_resources.tf"
  if_exists = "overwrite"
  contents  = <<EOF
resource "azurerm_resource_group" "terraform_state" {
  name     = "${local.env}-terraform-state-rg"
  location = "${local.region}"
  tags     = ${jsonencode(local.common_tags)}
}

resource "azurerm_storage_account" "terraform_state" {
  name                     = "${lower(local.env)}tfstate${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.terraform_state.name
  location                 = azurerm_resource_group.terraform_state.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
  }

  tags = ${jsonencode(local.common_tags)}
}

resource "azurerm_storage_container" "terraform_state" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.terraform_state.name
  container_access_type = "private"
}
EOF
}
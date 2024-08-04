terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.107.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.51.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "1.13.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.4.2"
    }
    http = {
      source = "hashicorp/http"
      version = "3.4.4"
    }
  }
}

provider "azurerm" {
  # skip_provider_registration = true
  features {}
}
terraform {
  required_version = ">= 1.9.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
    azuread = {
      source  = "hashicorp/azuread"
    }
    random = {
      source  = "hashicorp/random"
    }
    http = {
      source = "hashicorp/http"
    }
  }
}
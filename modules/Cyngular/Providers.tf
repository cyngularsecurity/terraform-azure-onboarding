terraform {
  required_version = ">= 1.9.5, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.25.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.2.0"
    }
  }
}
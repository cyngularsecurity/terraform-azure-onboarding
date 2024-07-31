terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.96.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.51.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}
provider "azuread" {
}
terraform {
  required_version = ">= 1.9.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.5.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.0.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
  }
}

provider "azurerm" {
  subscription_id = var.main_subscription_id
  features {}
}

provider "azuread" {
  tenant_id = data.azurerm_client_config.current.tenant_id
}
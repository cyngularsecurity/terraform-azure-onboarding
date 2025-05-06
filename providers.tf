terraform {
  required_version = ">= 1.9.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.25.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.2.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.5"
    }
  }
}

provider "azurerm" {
  subscription_id = var.main_subscription_id
  features {
    application_insights {
      disable_generated_rule = true
    }
  }
}

provider "azuread" {
  tenant_id = data.azurerm_client_config.current.tenant_id
}
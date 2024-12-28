terraform {
  required_version = ">= 1.9.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.14.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.0.2"
    }
    azapi = {
      source = "Azure/azapi"
      version = "2.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
    local = {
      source = "hashicorp/local"
      version = "2.5.2"
    }
    # null = {
    #   source  = "hashicorp/null"
    #   version = "3.2.2"
    # }
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

provider "azapi" {
  subscription_id = var.main_subscription_id
  tenant_id       = data.azurerm_client_config.current.tenant_id
}
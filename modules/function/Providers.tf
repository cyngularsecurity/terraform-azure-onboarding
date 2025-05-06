terraform {
  required_version = ">= 1.9.5, < 2.0"
  required_providers {
    http = {
      source  = "hashicorp/http"
      version = "3.4.5"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.25.0"
    }
  }
}
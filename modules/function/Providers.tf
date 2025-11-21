terraform {
  required_version = ">= 1.9.5, < 2.0"
  required_providers {
    http = {
      source  = "hashicorp/http"
    }
    local = {
      source  = "hashicorp/local"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}
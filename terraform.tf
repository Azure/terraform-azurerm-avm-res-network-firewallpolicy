terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.71"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.13"
    }
  }
}
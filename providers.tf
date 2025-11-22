terraform {
  required_version = "~> 1.9"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.47.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.4.0"
    }
  }

  backend "azurerm" {}
}

provider "azuread" {
  # Configuration options
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

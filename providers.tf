terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53.0"  # Pin to minor version for stability
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116.0"  # Pin to minor version for stability
    }
  }

  backend "azurerm" {
    # Backend configuration should be provided via CLI or environment variables
    # terraform init -backend-config="storage_account_name=xxx" -backend-config="resource_group_name=xxx"
  }
}

provider "azuread" {
  # Configuration options
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

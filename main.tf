terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.25.0"
    }
  }
  backend "azurerm" {
      resource_group_name   = ""
      storage_account_name  = ""
      container_name        = ""
      key                   = ""
      subscription_id       = ""
      use_azuread_auth      = true
  }
}

provider "azurerm" {
    features {}
    subscription_id = var.subscription_id
}
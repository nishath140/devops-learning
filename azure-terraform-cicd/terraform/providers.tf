terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=5.0.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstate45265391"
    container_name       = "tfstate"
    key                  = "azure-terraform-cicd.tfstate"

    use_azuread_auth = true
    use_cli          = true
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
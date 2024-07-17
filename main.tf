# Variables - move to seperate file when too many
variable "resource_prefix" {
  description = "Prefix for all resources"
  default     = "dapalpha"
}

variable "environment" {
  description = "Deployment environment"
  default     = "dev"
}

# Providers
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.112.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.53.1"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  skip_provider_registration = true
  features {
  }
}


resource "azurerm_resource_group" "rg_core" {
  name     = "coreinfra-rg"
  location = "UK South"
}


resource "azurerm_storage_account" "sc_infra" {
  name                     = "${var.resource_prefix}infra${var.environment}"
  resource_group_name      = azurerm_resource_group.rg_core.name
  location                 = azurerm_resource_group.rg_core.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "sc_infra_container" {
  name                 = "tfstate"
  storage_account_name = azurerm_storage_account.sc_infra.name
}

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

# Core infra

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


resource "azurerm_resource_group" "rg_data" {
  name     = "${var.resource_prefix}-data-${var.environment}-rg"
  location = "UK South"
}


# Create data lake for data rg
resource "azurerm_storage_account" "sc_datalake" {
  name                     = "${var.resource_prefix}datastlake${var.environment}"
  resource_group_name      = azurerm_resource_group.rg_data.name
  location                 = azurerm_resource_group.rg_data.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true # This enables DataLake Gen2.
}

resource "azurerm_storage_container" "sc_datalake_raw_container" {
  name                 = "raw"
  storage_account_name = azurerm_storage_account.sc_datalake.name
}

resource "azurerm_storage_container" "sc_datalake_processed_container" {
  name                 = "processed"
  storage_account_name = azurerm_storage_account.sc_datalake.name
}

resource "azurerm_storage_container" "sc_datalake_reporting_container" {
  name                 = "reporting"
  storage_account_name = azurerm_storage_account.sc_datalake.name
}


# ADF
resource "azurerm_data_factory" "adf-data" {
  name                = "${var.resource_prefix}-adf-data-${var.environment}"
  resource_group_name = azurerm_resource_group.rg_data.name
  location            = azurerm_resource_group.rg_data.location
  dynamic "github_configuration" {
    for_each = var.environment == "dev" ? [1] : []
    content {
      account_name    = "madetech"
      branch_name     = "main"
      repository_name = "dhsc-alpha-data"
      root_folder     = "/data_factory"
    }
  }
  identity {
    type = "SystemAssigned"
  }
}

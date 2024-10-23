variable "environment" {}
variable "resource_prefix" {}
variable "resource_group_name" {}
variable "location" {}

# Create drop storage account
resource "azurerm_storage_account" "drop_datalake" {
  name                     = "${var.resource_prefix}stdrop${var.environment}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true # This enables DataLake Gen2.
  allow_nested_items_to_be_public = false
}

# Create containers for the drop storage account 
resource "azurerm_storage_container" "datalake_drop_restricted" {
  name                 = "restricted"
  storage_account_name = azurerm_storage_account.drop_datalake.name
}

resource "azurerm_storage_container" "datalake_drop_unrestricted" {
  name                 = "unrestricted"
  storage_account_name = azurerm_storage_account.drop_datalake.name
}

# Create bronze storage account
resource "azurerm_storage_account" "bronze_datalake" {
  name                     = "${var.resource_prefix}stbronze${var.environment}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true # This enables DataLake Gen2.
  allow_nested_items_to_be_public = false
}

# Create containers for the bronze storage account
resource "azurerm_storage_container" "datalake_bronze_restricted" {
  name                 = "restricted"
  storage_account_name = azurerm_storage_account.bronze_datalake.name
}

resource "azurerm_storage_container" "datalake_bronze_unrestricted" {
  name                 = "unrestricted"
  storage_account_name = azurerm_storage_account.bronze_datalake.name
}

# Create silver storage account
resource "azurerm_storage_account" "silver_datalake" {
  name                     = "${var.resource_prefix}stsilver${var.environment}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true # This enables DataLake Gen2.
  allow_nested_items_to_be_public = false
}

# Create containers for the silver storage account
resource "azurerm_storage_container" "datalake_silver_restricted" {
  name                 = "restricted"
  storage_account_name = azurerm_storage_account.silver_datalake.name
}

resource "azurerm_storage_container" "datalake_silver_unrestricted" {
  name                 = "unrestricted"
  storage_account_name = azurerm_storage_account.silver_datalake.name
}

# Create gold storage account
resource "azurerm_storage_account" "gold_datalake" {
  name                     = "${var.resource_prefix}stgold${var.environment}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true # This enables DataLake Gen2.
  allow_nested_items_to_be_public = false
}

# Create containers for the gold storage account
resource "azurerm_storage_container" "datalake_gold_restricted" {
  name                 = "restricted"
  storage_account_name = azurerm_storage_account.gold_datalake.name
}

resource "azurerm_storage_container" "datalake_gold_unrestricted" {
  name                 = "unrestricted"
  storage_account_name = azurerm_storage_account.gold_datalake.name
}
variable "environment" {}
variable "resource_prefix" {}
variable "resource_group_name" {}
variable "location" {}
variable "tenant_id" {}

resource "azuread_group" "secret_readers" {
  display_name     = format("%s - %s", "DAP Alpha - Secret readers", upper(var.environment))
  security_enabled = true
}

resource "azuread_group" "secret_readers" {
  display_name     = format("%s - %s", "DAP Alpha - Key vault admin", upper(var.environment))
  security_enabled = true
}


resource "azurerm_key_vault" "key_vault" {
  name                     = "${var.resource_prefix}-kv-${var.environment}"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  tenant_id                = var.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = false
}


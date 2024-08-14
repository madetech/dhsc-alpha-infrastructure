variable "environment" {}
variable "resource_prefix" {}
variable "resource_group_name" {}
variable "location" {}
variable "tenant_id" {}
variable "adf_object_id" {}

resource "azuread_group" "secret_readers" {
  display_name     = format("%s - %s", "DAP Alpha - Secret readers", upper(var.environment))
  security_enabled = true
}

resource "azuread_group" "kv_admins" {
  display_name     = format("%s - %s", "DAP Alpha - Key vault admin", upper(var.environment))
  security_enabled = true
}

resource "azuread_group_member" "adf_secret_read" {
  group_object_id  = azurerm_key_vault_access_policy.secret_readers.object_id
  member_object_id = var.adf_object_id
}

resource "azurerm_key_vault" "key_vault" {
  name                     = "${var.resource_prefix}-kv-${var.environment}"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  tenant_id                = var.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = false
}


resource "azurerm_key_vault_access_policy" "kv_admins" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = var.tenant_id
  object_id    = azuread_group.kv_admins.object_id
  certificate_permissions = [
    "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers",
    "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers",
    "Purge", "Recover", "Restore", "SetIssuers", "Update"
  ]
  key_permissions = [
    "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import",
    "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update",
    "Verify", "WrapKey", "Release", "Rotate", "GetRotationPolicy", "SetRotationPolicy"
  ]
  secret_permissions = [
    "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
  ]
  storage_permissions = [
    "Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Purge",
    "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"
  ]
}

resource "azurerm_key_vault_access_policy" "secret_readers" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = var.tenant_id
  object_id    = azuread_group.secret_readers.object_id
  secret_permissions = [
    "Get", "List"
  ]
}

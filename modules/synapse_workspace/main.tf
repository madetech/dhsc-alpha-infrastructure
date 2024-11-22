# variable "resource_prefix" {}
# variable "resource_group_name" {}
# variable "location" {}
# variable "environment" {}

# # Create synapse storage account
# resource "azurerm_storage_account" "synapse_storage_account" {
#   name                     = "${var.resource_prefix}syndatast${var.environment}"
#   resource_group_name      = var.resource_group_name
#   location                 = var.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
#   is_hns_enabled           = true # This enables DataLake Gen2.
#   allow_nested_items_to_be_public = false
# }

# # Create synapse filesystem
# resource "azurerm_storage_data_lake_gen2_filesystem" "synapse_filesystem" {
#   name                 = "${var.resource_prefix}syndatafs${var.environment}"
#   storage_account_id = azurerm_storage_account.synapse_storage_account.id
# }


# # Create synapse workspace
# resource "azurerm_synapse_workspace" "synapse_workspace" {
#   name                                 = "${var.resource_prefix}syndata${var.environment}"
#   resource_group_name                  = var.resource_group_name
#   location                             = var.location
#   storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse_filesystem.id
#   sql_administrator_login              = "???"
#   sql_administrator_login_password     = "??"

#   identity {
#     type = "SystemAssigned"
#   }
# }
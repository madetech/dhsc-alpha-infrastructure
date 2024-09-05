variable "environment" {}
variable "resource_prefix" {}
variable "resource_group_name" {}
variable "location" {}

# Create databricks workspace 
resource "azurerm_databricks_workspace" "dbx_workspace" {
  name                = "${var.resource_prefix}-dbx-data-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "premium"
  custom_parameters {
    storage_account_name = "${var.resource_prefix}dbxdatadbfs${var.environment}"
  }
}

output "workspace_url" {
  value = azurerm_databricks_workspace.dbx_workspace.workspace_url
}

output "workspace_id" {
  value = azurerm_databricks_workspace.dbx_workspace.id
}

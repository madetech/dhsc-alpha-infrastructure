variable "environment" {}
variable "location" {}
variable "resource_prefix" {}


resource "azurerm_resource_group" "functions_rg" {
  name     = "${var.resource_prefix}-functions-${var.environment}-rg"
  location = var.location
}


resource "azurerm_storage_account" "sa_functions" {
  name                     = "${var.resource_prefix}functions${var.environment}"
  resource_group_name      = azurerm_resource_group.functions_rg.name
  location                 = azurerm_resource_group.functions_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "sp_functions" {
  name                = "${var.resource_prefix}-asp-functions-${var.environment}"
  resource_group_name = azurerm_resource_group.functions_rg.name
  location            = azurerm_resource_group.functions_rg.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "func_app" {
  name                = "${var.resource_prefix}-func-app-${var.environment}"
  resource_group_name = azurerm_resource_group.functions_rg.name
  location            = azurerm_resource_group.functions_rg.location

  storage_account_name          = azurerm_storage_account.sa_functions.name
  storage_uses_managed_identity = true
  service_plan_id               = azurerm_service_plan.sp_functions.id

  identity {
    type = "SystemAssigned"
  }

  site_config {

  }
}

resource "azurerm_role_assignment" "func_storage_access" {
  scope                            = azurerm_storage_account.sa_functions.id
  role_definition_name             = "Storage Account Contributor"
  principal_id                     = azurerm_linux_function_app.func_app.identity[0].principal_id
  skip_service_principal_aad_check = false
  depends_on                       = [azurerm_service_plan.sp_functions]
}

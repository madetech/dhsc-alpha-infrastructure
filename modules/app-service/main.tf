variable "environment" {}
variable "location" {}
variable "dap_acr_id" {}
variable "dap_acr_registry_url" {}
variable "docker_image" {}
variable "resource_prefix" {}


resource "azurerm_resource_group" "frontend_rg" {
  name     = "${var.resource_prefix}-${var.environment}-rg"
  location = var.location
}
resource "azurerm_user_assigned_identity" "dap_alpha_assigned_identity" {
  name                = "${var.resource_prefix}-${var.environment}-ai"
  resource_group_name = azurerm_resource_group.frontend_rg.name
  location            = azurerm_resource_group.frontend_rg.location
}


resource "azurerm_role_assignment" "webapp_acr_pull" {
  scope                            = var.dap_acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_user_assigned_identity.dap_alpha_assigned_identity.principal_id
  skip_service_principal_aad_check = false
}


resource "azurerm_service_plan" "dap_alpha_service_plan" {
  name                = "${var.resource_prefix}-${var.environment}-service-plan"
  resource_group_name = azurerm_resource_group.frontend_rg.name
  location            = azurerm_resource_group.frontend_rg.location
  os_type             = "Linux"
  sku_name            = "B2"
}

resource "azurerm_linux_web_app" "dap-alpha-app" {
  name                = "${var.resource_prefix}-${var.environment}-app"
  resource_group_name = azurerm_resource_group.frontend_rg.name
  location            = var.location
  service_plan_id     = azurerm_service_plan.dap_alpha_service_plan.id

   site_config {
    always_on                               = false
    container_registry_use_managed_identity = true
    application_stack {
      docker_image_name   = var.docker_image
      docker_registry_url = "https://${var.dap_acr_registry_url}"
    }
  }
  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.dap_alpha_assigned_identity.id]
  }
  app_settings = {
    "CONTAINER_PORT"              = 8080
  }
}


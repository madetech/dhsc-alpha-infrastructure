variable "environment" {}
variable "location" {}
variable "dap_acr_id" {}
variable "dap_acr_registry_url" {}
variable "docker_image" {}
variable "resource_prefix" {}

resource "azuread_application" "app_dap_alpha_auth" {
  display_name = "${var.resource_prefix}-auth-${var.environment}"
}

resource "azuread_service_principal" "sp_dap_alpha_auth" {
  client_id = azuread_application.app_dap_alpha_auth.client_id
}

resource "time_rotating" "sp_dap_alpha_auth_rotation" {
  rotation_days = 30
}

resource "azuread_service_principal_password" "sp_dap_alpha_auth_secret" {
  service_principal_id = azuread_service_principal.sp_dap_alpha_auth.object_id
  rotate_when_changed = {
    rotation = time_rotating.sp_dap_alpha_auth_rotation.id
  }
}


resource "azurerm_resource_group" "frontend_rg" {
  name     = "${var.resource_prefix}-${var.environment}-rg"
  location = var.location
}
resource "azurerm_user_assigned_identity" "dap_alpha_assigned_identity" {
  name                = "${var.resource_prefix}-${var.environment}-ai"
  resource_group_name = azurerm_resource_group.frontend_rg.name
  location            = azurerm_resource_group.frontend_rg.location
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
    "CONTAINER_PORT" = 8080
  }
  auth_settings_v2 {
    auth_enabled           = true
    require_authentication = true
    #default_provider = "azureactivedirectory"
    microsoft_v2 {
      client_id                  = azuread_service_principal.sp_dap_alpha_auth.client_id
      client_secret_setting_name = azuread_service_principal_password.sp_dap_alpha_auth_secret.display_name
    }
    login {
      token_store_enabled = true
    }
  }
}

resource "azurerm_role_assignment" "webapp_scheduling_acr_pull" {
  scope                            = var.dap_acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_linux_web_app.dap-alpha-app.identity[0].principal_id
  skip_service_principal_aad_check = false
}

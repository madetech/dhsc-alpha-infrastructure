variable "environment" {}
variable "location" {}
variable "resource_prefix" {}
variable "sql_readers_group_id" {}
variable "tenant_id" {}

# App registration for authentication
resource "azuread_application_registration" "func_dap_alpha_auth" {
  display_name                       = "${var.resource_prefix}-auth-${var.environment}"
  implicit_id_token_issuance_enabled = true
  requested_access_token_version     = 2
}

resource "azuread_service_principal" "sp_dap_func_auth" {
  client_id = azuread_application_registration.func_dap_alpha_auth.client_id
}

resource "time_rotating" "sp_dap_func_auth_rotation" {
  rotation_days = 30
}

resource "azuread_service_principal_password" "sp_dap_func_auth_secret" {
  service_principal_id = azuread_service_principal.sp_dap_func_auth.object_id
  display_name         = "${var.resource_prefix}-auth-secret-${var.environment}"
  rotate_when_changed = {
    rotation = time_rotating.sp_dap_func_auth_rotation.id
  }
}


# Functions resources
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

resource "azurerm_user_assigned_identity" "functions_assigned_identity" {
  name                = "${var.resource_prefix}-ai-functions-${var.environment}"
  resource_group_name = azurerm_resource_group.functions_rg.name
  location            = azurerm_resource_group.functions_rg.location
}

resource "azurerm_linux_function_app" "func_app" {
  name                = "${var.resource_prefix}-func-app-${var.environment}"
  resource_group_name = azurerm_resource_group.functions_rg.name
  location            = azurerm_resource_group.functions_rg.location

  storage_account_name = azurerm_storage_account.sa_functions.name
  #storage_uses_managed_identity = true
  storage_account_access_key = azurerm_storage_account.sa_functions.primary_access_key
  service_plan_id            = azurerm_service_plan.sp_functions.id

  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.functions_assigned_identity.id]
  }

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }
  app_settings = {
    "MANAGED_IDENTITY_CLIENT_ID" = azurerm_user_assigned_identity.functions_assigned_identity.client_id
  }
  auth_settings_v2 {
    auth_enabled           = true
    require_authentication = true
    default_provider       = "azureactivedirectory"
    active_directory_v2 {
      client_id                  = azuread_service_principal.sp_dap_func_auth.client_id
      tenant_auth_endpoint       = "https://login.microsoftonline.com/${var.tenant_id}/v2.0/"
      client_secret_setting_name = azuread_service_principal_password.sp_dap_func_auth_secret.display_name
    }
    login {
      token_store_enabled = true
    }
  }

}

resource "azuread_application_redirect_uris" "func_dap_alpha_auth_redirect_uris" {
  application_id = azuread_application_registration.func_dap_alpha_auth.id
  type           = "Web"
  redirect_uris = [
    "https://${azurerm_linux_function_app.func_app.default_hostname}/.auth/login/aad/callback"
  ]
}


resource "azurerm_role_assignment" "func_storage_access" {
  scope                            = azurerm_storage_account.sa_functions.id
  role_definition_name             = "Storage Account Contributor"
  principal_id                     = azurerm_linux_function_app.func_app.identity[0].principal_id
  skip_service_principal_aad_check = false
  depends_on                       = [azurerm_service_plan.sp_functions]
}

resource "azuread_group_member" "sql_readers_group_member" {
  group_object_id  = var.sql_readers_group_id
  member_object_id = azurerm_user_assigned_identity.functions_assigned_identity.principal_id
}

output "function_base_url" {
  value = azurerm_linux_function_app.func_app.default_hostname
}



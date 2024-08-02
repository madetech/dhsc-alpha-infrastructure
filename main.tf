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
    time = {
      source  = "hashicorp/time"
      version = "0.12.0"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  skip_provider_registration = true
  features {
  }
}

provider "azuread" {
  tenant_id = "fe486d5c-e2e4-4d1d-9af1-9c4f44b434b2"
}

data "azurerm_client_config" "current" {}

# Core infra

resource "azurerm_resource_group" "rg_core" {
  name     = "coreinfra-rg"
  location = "UK South"
}

# Entra groups
resource "azuread_group" "sql_admin_group" {
  display_name     = format("%s - %s", "DAP Alpha - SQL Admins", upper(var.environment))
  security_enabled = true
}

resource "azuread_group" "sql_reader_group" {
  display_name     = "DAP Alpha - SQL Readers - ${upper(var.environment)}"
  security_enabled = true
}


resource "azuread_group" "sql_writer_group" {
  display_name     = "DAP Alpha - SQL Writers - ${upper(var.environment)}"
  security_enabled = true
}


# Infrastructure

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
resource "azurerm_data_factory" "adf_data" {
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

# Create MS SQL database for data rg - nwldatasql
resource "azurerm_mssql_server" "data_sql" {
  name                = "${var.resource_prefix}-sql-data-${var.environment}"
  resource_group_name = azurerm_resource_group.rg_data.name
  location            = azurerm_resource_group.rg_data.location
  version             = "12.0"
  minimum_tls_version = "1.2"

  azuread_administrator {
    login_username              = azuread_group.sql_admin_group.display_name
    object_id                   = azuread_group.sql_admin_group.id
    azuread_authentication_only = true
  }

  identity {
    type = "SystemAssigned"
  }

}

# Create MS SQL database for data rg 
resource "azurerm_mssql_database" "data_db_sql" {
  name           = "Analytical_Datastore"
  server_id      = azurerm_mssql_server.data_sql.id
  sku_name       = "Basic"
  zone_redundant = false
}

resource "azurerm_mssql_firewall_rule" "sql_internalazure" {
  name             = "AllowAllWindowsAzureIps" # Azure needs this exact name for this rule
  server_id        = azurerm_mssql_server.data_sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}


# Make ADF an admin of the SQL server - temporary
resource "azuread_group_member" "adf_sql_access" {
  group_object_id  = azuread_group.sql_admin_group.id
  member_object_id = azurerm_data_factory.adf_data.identity[0].principal_id
}


resource "azurerm_role_assignment" "adf_lake_access" {
  scope                = azurerm_storage_account.sc_datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.adf_data.identity[0].principal_id
}

# Assign directory role to SQL server
resource "azuread_directory_role" "directory_reader" {
  display_name = "Directory Readers"
}

resource "azuread_directory_role_assignment" "sql_server_directory_readers" {
  principal_object_id = azurerm_mssql_server.data_sql.identity[0].principal_id
  role_id             = azuread_directory_role.directory_reader.template_id
}

module "acr" {
  source          = "./modules/acr"
  acr_rg          = azurerm_resource_group.rg_core.name
  acr_location    = var.location
  resource_prefix = var.resource_prefix
  environment     = var.environment
}

module "app_registrations" {
  source          = "./modules/app_registrations"
  resource_prefix = var.resource_prefix
  environment     = var.environment
}

module "functions" {
  source                          = "./modules/functions"
  environment                     = var.environment
  location                        = var.location
  resource_prefix                 = var.resource_prefix
  sql_readers_group_id            = azuread_group.sql_reader_group.id
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  function_sp_client_id           = module.app_registrations.function_sp_client_id
  function_sp_secret_display_name = module.app_registrations.function_sp_secret_display_name
  app_registration_function_id    = module.app_registrations.app_registration_function_id
  app_registration_app_client_id  = module.app_registrations.app_registration_app_client_id
}


module "app_service" {
  source                     = "./modules/app-service"
  environment                = var.environment
  location                   = var.location
  dap_acr_id                 = module.acr.acr_id
  dap_acr_registry_url       = module.acr.registry_url
  docker_image               = var.docker_frontend_image
  resource_prefix            = var.resource_prefix
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  function_app_url           = module.functions.function_base_url
  app_sp_client_id           = module.app_registrations.app_sp_client_id
  app_sp_secret_display_name = module.app_registrations.app_sp_secret_display_name
  function_sp_client_id      = module.app_registrations.function_sp_client_id
  app_registration_app_id    = module.app_registrations.app_registration_app_id
}

moved {
  from = module.app_service.azuread_application_registration.app_dap_alpha_auth
  to   = module.app_registrations.azuread_application_registration.app_auth
}

moved {
  from = module.app_service.azuread_service_principal.sp_dap_alpha_auth
  to   = module.app_registrations.azuread_service_principal.app_auth
}
moved {
  from = module.app_service.azuread_service_principal_password.sp_dap_alpha_auth_secret
  to   = module.app_registrations.azuread_service_principal_password.app_auth
}
moved {
  from = module.app_service.time_rotating.sp_dap_alpha_auth_rotation
  to   = module.app_registrations.time_rotating.sp_app_auth_rotation
}
moved {
  from = module.app_service.azuread_service_principal_password.sp_dap_alpha_auth_secret
  to   = module.app_registrations.azuread_service_principal_password.app_auth
}
moved {
  from = module.functions.time_rotating.sp_dap_func_auth_rotation
  to   = module.app_registrations.time_rotating.sp_function_auth_rotation
}

moved {
  from = module.functions.azuread_service_principal_password.sp_dap_func_auth_secret
  to   = module.app_registrations.azuread_service_principal_password.function_auth
}
moved {
  from = module.functions.azuread_service_principal.sp_dap_func_auth
  to   = module.app_registrations.azuread_service_principal.function_auth
}
moved {
  from = module.functions.azuread_application_registration.func_dap_alpha_auth
  to   = module.app_registrations.azuread_application_registration.function_auth
}
moved {
  from = module.app_service.azuread_service_principal_delegated_permission_grant.app_auth_func_perm
  to   = module.app_registrations.azuread_service_principal_delegated_permission_grant.app_auth_function
}

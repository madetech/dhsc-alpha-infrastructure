variable "environment" {}
variable "location" {}
variable "resource_prefix" {}


resource "azuread_application_registration" "app_dap_alpha_auth" {
  display_name                       = "${var.resource_prefix}-auth-${var.environment}"
  implicit_id_token_issuance_enabled = true
  requested_access_token_version     = 2
}

resource "azuread_service_principal" "sp_dap_alpha_auth" {
  client_id = azuread_application_registration.app_dap_alpha_auth.client_id
}

resource "time_rotating" "sp_dap_alpha_auth_rotation" {
  rotation_days = 30
}

resource "azuread_service_principal_password" "sp_dap_alpha_auth_secret" {
  service_principal_id = azuread_service_principal.sp_dap_alpha_auth.object_id
  display_name         = "${var.resource_prefix}-auth-secret-${var.environment}"
  rotate_when_changed = {
    rotation = time_rotating.sp_dap_alpha_auth_rotation.id
  }
}


output "app_registration_id" {
  value = azuread_application_registration.app_dap_alpha_auth.id
}

output "service_principal_password_display_name" {
  value = azuread_service_principal_password.sp_dap_alpha_auth_secret.display_name
}

output "service_principal_client_id" {
  value = azuread_service_principal.sp_dap_alpha_auth.client_id
}

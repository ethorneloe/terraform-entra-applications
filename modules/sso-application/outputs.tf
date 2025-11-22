# Outputs for SSO Application Module

# Application outputs
output "application_id" {
  description = "The Application (client) ID"
  value       = azuread_application.app.client_id
}

output "application_object_id" {
  description = "The Application object ID"
  value       = azuread_application.app.object_id
}

output "application_id_uri" {
  description = "The Application ID URI"
  value       = try(azuread_application.app.identifier_uris[0], null)
}

output "display_name" {
  description = "The display name of the application"
  value       = azuread_application.app.display_name
}

# Service principal outputs
output "service_principal_id" {
  description = "The Service Principal object ID"
  value       = azuread_service_principal.app_sp.object_id
}

output "service_principal_application_id" {
  description = "The Service Principal application (client) ID"
  value       = azuread_service_principal.app_sp.client_id
}

output "service_principal_display_name" {
  description = "The Service Principal display name"
  value       = azuread_service_principal.app_sp.display_name
}

# Client secret outputs
output "client_secret" {
  description = "The client secret value (sensitive)"
  value       = try(azuread_application_password.app_password[0].value, null)
  sensitive   = true
}

output "client_secret_key_id" {
  description = "The key ID of the client secret"
  value       = try(azuread_application_password.app_password[0].key_id, null)
}

output "client_secret_end_date" {
  description = "The end date of the client secret"
  value       = try(azuread_application_password.app_password[0].end_date, null)
}

# Certificate outputs
output "certificate_key_id" {
  description = "The key ID of the certificate"
  value       = try(azuread_application_certificate.app_cert[0].key_id, null)
}

output "certificate_thumbprint" {
  description = "The thumbprint of the certificate"
  value       = try(azuread_application_certificate.app_cert[0].thumbprint, null)
}

# API permissions outputs
output "oauth2_permission_scope_ids" {
  description = "Map of OAuth2 permission scope names to their IDs"
  value = var.api_oauth2_permission_scopes != null ? {
    for scope in var.api_oauth2_permission_scopes : scope.value => scope.id
  } : {}
}

output "app_role_ids" {
  description = "Map of app role values to their IDs"
  value = var.app_roles != null ? {
    for role in var.app_roles : role.value => role.id
  } : {}
}

# Federated credentials outputs
output "federated_identity_credential_ids" {
  description = "Map of federated identity credential display names to their IDs"
  value = var.federated_identity_credentials != null ? {
    for idx, cred in azuread_application_federated_identity_credential.federated_cred :
    cred.display_name => cred.id
  } : {}
}

# Admin consent status
output "admin_consent_granted" {
  description = "Whether admin consent was granted"
  value       = var.enable_admin_consent && var.admin_consent_scope != null
}

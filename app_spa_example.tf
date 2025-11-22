# Example: Single Page Application (SPA)
# This example demonstrates creating a SPA with PKCE flow and Microsoft Graph permissions

module "spa_example" {
  source = "./modules/sso-application"

  # Basic application properties
  display_name     = "Example SPA App - ${var.environment}"
  description      = "Example single page application using PKCE authentication flow"
  sign_in_audience = "AzureADMyOrg"
  app_owners       = var.app_owners
  tags             = concat(["SPA", "Example"], [for k, v in local.common_tags : "${k}:${v}"])

  # SPA redirect URIs (uses PKCE, no client secret needed)
  spa_redirect_uris = [
    "http://localhost:3000",
    "http://localhost:3000/auth/callback",
    "https://example-spa-${var.environment}.${var.tenant_domain}",
    "https://example-spa-${var.environment}.${var.tenant_domain}/auth/callback"
  ]

  # API permissions - Microsoft Graph delegated permissions only
  required_resource_access = [
    {
      # Microsoft Graph
      resource_app_id = "00000003-0000-0000-c000-000000000000"
      resource_access = [
        {
          # User.Read - Delegated permission
          id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
          type = "Scope"
        },
        {
          # Mail.Read - Delegated permission
          id   = "570282fd-fa5c-430d-a7fd-fc8dc98a9dca"
          type = "Scope"
        },
        {
          # Calendars.Read - Delegated permission
          id   = "465a38f9-76ea-45b9-9f34-9e8b0d4b0b42"
          type = "Scope"
        }
      ]
    }
  ]

  # Service principal configuration
  app_role_assignment_required  = false
  preferred_single_sign_on_mode = "oidc"

  # No client secret for SPA (uses PKCE)
  create_client_secret = false

  # Admin consent for delegated permissions
  enable_admin_consent                 = var.enable_admin_consent
  admin_consent_scope                  = ["User.Read", "Mail.Read", "Calendars.Read"]
  resource_service_principal_object_id = data.azuread_service_principal.microsoft_graph.object_id

  # Optional claims for enhanced security
  optional_claims = {
    id_token = [
      {
        name                  = "email"
        essential             = true
        additional_properties = []
      },
      {
        name                  = "family_name"
        essential             = false
        additional_properties = []
      },
      {
        name                  = "given_name"
        essential             = false
        additional_properties = []
      }
    ]
    access_token = [
      {
        name      = "email"
        essential = true
      }
    ]
  }
}

# Output the application details
output "spa_example_application_id" {
  description = "Application (client) ID for Example SPA"
  value       = module.spa_example.application_id
}

output "spa_example_service_principal_id" {
  description = "Service Principal Object ID for Example SPA"
  value       = module.spa_example.service_principal_id
}

# Example: Web API Application with Microsoft Graph Permissions
# This example demonstrates creating a web API application with delegated and application permissions

module "web_api_example" {
  source = "./modules/sso-application"

  # Basic application properties
  display_name     = "Example Web API - ${var.environment}"
  description      = "Example web API application with Microsoft Graph permissions"
  sign_in_audience = "AzureADMyOrg"
  app_owners       = var.app_owners
  tags             = concat(["WebAPI", "Example"], [for k, v in local.common_tags : "${k}:${v}"])

  # Application ID URI
  identifier_uris = ["api://example-web-api-${var.environment}"]

  # Web application redirect URIs
  web_redirect_uris = [
    "https://example-api-${var.environment}.${var.tenant_domain}/auth/callback",
    "https://localhost:5001/auth/callback"
  ]

  # API permissions - Microsoft Graph
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
          # User.Read.All - Application permission
          id   = "df021288-bdef-4463-88db-98f22de89214"
          type = "Role"
        },
        {
          # Group.Read.All - Application permission
          id   = "5b567255-7703-4780-807c-7be8301ae99b"
          type = "Role"
        }
      ]
    }
  ]

  # Expose API with custom scopes
  expose_api                     = true
  requested_access_token_version = 2
  api_oauth2_permission_scopes = [
    {
      admin_consent_description  = "Allow the application to read data on behalf of the signed-in user"
      admin_consent_display_name = "Read data"
      enabled                    = true
      id                         = "a1b2c3d4-e5f6-4a5b-8c7d-9e8f7a6b5c4d"
      type                       = "User"
      user_consent_description   = "Allow the application to read your data"
      user_consent_display_name  = "Read your data"
      value                      = "Data.Read"
    },
    {
      admin_consent_description  = "Allow the application to write data on behalf of the signed-in user"
      admin_consent_display_name = "Write data"
      enabled                    = true
      id                         = "b2c3d4e5-f6a7-4b5c-8d7e-9f8a7b6c5d4e"
      type                       = "User"
      user_consent_description   = "Allow the application to write your data"
      user_consent_display_name  = "Write your data"
      value                      = "Data.Write"
    }
  ]

  # App roles for application permissions
  app_roles = [
    {
      allowed_member_types = ["Application"]
      description          = "Applications can read all data"
      display_name         = "Data Reader"
      enabled              = true
      id                   = "c3d4e5f6-a7b8-4c5d-8e7f-9a8b7c6d5e4f"
      value                = "Data.Read.All"
    }
  ]

  # Service principal configuration
  app_role_assignment_required  = false
  preferred_single_sign_on_mode = "oidc"
  notification_email_addresses  = ["admin@${var.tenant_domain}"]

  # Client secret configuration
  create_client_secret      = true
  client_secret_display_name = "Terraform Managed Secret"
  password_rotation_days     = var.password_rotation_days

  # Admin consent (if enabled at environment level)
  enable_admin_consent                 = var.enable_admin_consent
  admin_consent_scope                  = ["User.Read"]
  resource_service_principal_object_id = data.azuread_service_principal.microsoft_graph.object_id

  # Optional claims
  optional_claims = {
    access_token = [
      {
        name      = "groups"
        essential = false
      },
      {
        name      = "email"
        essential = true
      }
    ]
    id_token = [
      {
        name      = "groups"
        essential = false
      }
    ]
  }

  # Group membership claims
  group_membership_claims = ["SecurityGroup", "ApplicationGroup"]
}

# Output the application details
output "web_api_example_application_id" {
  description = "Application (client) ID for Example Web API"
  value       = module.web_api_example.application_id
}

output "web_api_example_service_principal_id" {
  description = "Service Principal Object ID for Example Web API"
  value       = module.web_api_example.service_principal_id
}

output "web_api_example_client_secret" {
  description = "Client Secret for Example Web API (sensitive)"
  value       = module.web_api_example.client_secret
  sensitive   = true
}

output "web_api_example_application_id_uri" {
  description = "Application ID URI for Example Web API"
  value       = module.web_api_example.application_id_uri
}

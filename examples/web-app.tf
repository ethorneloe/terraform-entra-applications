# Example: Web Application
#
# Microsoft terminology: "Web apps" (confidential client)
# https://learn.microsoft.com/en-us/entra/identity-platform/v2-app-types#web-apps
#
# Use case: Traditional web applications with server-side code
# Auth flow: Authorization Code + PKCE (OAuth 2.0 / OpenID Connect)
# User logs in via browser, app gets tokens on behalf of user
#
# Examples:
# - ASP.NET Core web apps
# - Django/Flask applications
# - Node.js/Express apps
# - Any server-rendered web application

module "employee_portal" {
  source = "../modules/sso-application"

  # Pattern auto-applies security defaults:
  # - Disables implicit grant flow (forces PKCE)
  # - Sets preferred SSO mode to "oidc"
  # - Configures secure defaults
  app_pattern  = "web_app"
  display_name = "Employee Portal"
  description  = "Internal employee self-service portal"

  # Redirect URIs for your web application
  web_redirect_uris = [
    "https://portal.example.com/signin-oidc",
    "https://portal.example.com/auth/callback",
    "https://localhost:5001/signin-oidc" # Local development
  ]

  # Logout URL (optional)
  # logout_url = "https://portal.example.com/signout"

  # Delegated permissions (acts on behalf of signed-in user)
  # Use permission helpers - much easier than GUIDs!
  graph_delegated_permissions = [
    "User.Read",  # Read user's profile
    "openid",     # OpenID Connect scopes
    "email",
    "profile"
  ]

  # Optional claims in tokens (minimize for performance)
  optional_claims = {
    id_token = [
      { name = "email", essential = true, source = null, additional_properties = null },
      { name = "preferred_username", essential = false, source = null, additional_properties = null }
    ]
    access_token = [
      { name = "groups", essential = false, source = null, additional_properties = null }
    ]
    saml2_token = null
  }

  # Group claims in tokens
  group_membership_claims = ["SecurityGroup"]

  # PKCE is enforced by default (require_pkce = true)
  # Implicit grant is disabled by pattern

  # Client secret (stored in state - use Key Vault in production)
  create_client_secret   = true
  password_rotation_days = 180

  # Production safety
  prevent_destroy = true
  notes           = "Employee portal for HR, payroll, and benefits"

  tags = local.common_tag_list
}

# Outputs for application configuration
output "employee_portal_config" {
  description = "OIDC configuration for employee portal"
  value = {
    tenant_id     = local.tenant_id
    client_id     = module.employee_portal.application_id
    client_secret = module.employee_portal.client_secret
    authority     = "https://login.microsoftonline.com/${local.tenant_id}"
    redirect_uri  = "https://portal.example.com/signin-oidc"
    scopes        = ["openid", "profile", "email", "User.Read"]
  }
  sensitive = true
}

# Example: App configuration for ASP.NET Core
output "employee_portal_appsettings" {
  description = "appsettings.json snippet for ASP.NET Core"
  value = <<-EOT
    {
      "AzureAd": {
        "Instance": "https://login.microsoftonline.com/",
        "TenantId": "${local.tenant_id}",
        "ClientId": "${module.employee_portal.application_id}",
        "ClientSecret": "<from-key-vault>",
        "CallbackPath": "/signin-oidc",
        "SignedOutCallbackPath": "/signout-callback-oidc"
      }
    }
  EOT
}

# Example: Single Page Application (SPA)
#
# Use case: JavaScript-heavy apps running entirely in browser
# Auth flow: Authorization Code + PKCE (OAuth 2.0)
# No client secret (public client - can't keep secrets secure)
#
# Examples:
# - React, Vue, Angular applications
# - Modern JavaScript frameworks
# - Progressive Web Apps (PWAs)

module "dashboard_spa" {
  source = "../modules/sso-application"

  # Pattern auto-applies security defaults for SPAs:
  # - Enforces PKCE (SPAs are public clients)
  # - Disables implicit grant flow (deprecated for SPAs)
  # - No client secret (SPAs can't keep secrets)
  app_pattern  = "oidc_spa"
  display_name = "Analytics Dashboard"
  description  = "Real-time analytics dashboard (React SPA)"

  # SPA redirect URIs (must match your app's redirect configuration)
  spa_redirect_uris = [
    "https://dashboard.example.com/auth/callback",
    "https://dashboard.example.com",
    "http://localhost:3000",      # Local development
    "http://localhost:3000/callback"
  ]

  # Delegated permissions (user must be signed in)
  required_resource_access = [{
    resource_app_id = local.microsoft_graph_app_id
    resource_access = [
      {
        id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
        type = "Scope"
      },
      {
        id   = "37f7f235-527c-4136-accd-4a02d197296e" # openid
        type = "Scope"
      },
      {
        id   = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0" # email
        type = "Scope"
      }
    ]
  }]

  # SPAs don't use client secrets (public clients)
  create_client_secret = false

  # Optional claims for SPA tokens
  optional_claims = {
    id_token = [
      { name = "email", essential = true, source = null, additional_properties = null }
    ]
    access_token = [
      { name = "groups", essential = false, source = null, additional_properties = null }
    ]
    saml2_token = null
  }

  # Enable CORS if calling Microsoft Graph directly from browser
  # (Not recommended - use backend-for-frontend pattern instead)

  tags = local.common_tag_list
  notes = "Analytics dashboard - React SPA with MSAL.js"
}

# Outputs for SPA configuration
output "dashboard_spa_config" {
  description = "MSAL.js configuration for React SPA"
  value = {
    client_id = module.dashboard_spa.application_id
    authority = "https://login.microsoftonline.com/${local.tenant_id}"
    redirect_uri = "https://dashboard.example.com/auth/callback"
    scopes = ["User.Read", "openid", "profile", "email"]
  }
}

# Example: MSAL.js configuration
output "dashboard_msal_config" {
  description = "MSAL configuration object for JavaScript"
  value = <<-EOT
    // src/authConfig.js
    export const msalConfig = {
      auth: {
        clientId: "${module.dashboard_spa.application_id}",
        authority: "https://login.microsoftonline.com/${local.tenant_id}",
        redirectUri: window.location.origin + "/auth/callback",
        postLogoutRedirectUri: window.location.origin
      },
      cache: {
        cacheLocation: "sessionStorage", // or "localStorage"
        storeAuthStateInCookie: false
      }
    };

    export const loginRequest = {
      scopes: ["User.Read", "openid", "profile", "email"]
    };

    // Usage with @azure/msal-browser:
    // import { PublicClientApplication } from "@azure/msal-browser";
    // const msalInstance = new PublicClientApplication(msalConfig);
  EOT
}

# Security notes for SPA deployments
output "spa_security_notes" {
  description = "Important security considerations for SPAs"
  value = <<-EOT
    ⚠️  SPA SECURITY BEST PRACTICES:

    1. PKCE is MANDATORY - automatically enforced by app_pattern = "oidc_spa"
    2. No client secrets - SPAs are public clients
    3. Use sessionStorage (not localStorage) for tokens when possible
    4. Implement token refresh properly (MSAL handles this)
    5. Don't call Graph API directly from browser - use BFF (backend-for-frontend)
    6. Validate tokens on your backend API
    7. Enable HTTPS everywhere (no HTTP in production)
    8. Configure Content Security Policy (CSP) headers
    9. Keep MSAL.js library up to date

    📚 Learn more:
    - https://github.com/AzureAD/microsoft-authentication-library-for-js
    - https://learn.microsoft.com/en-us/azure/active-directory/develop/scenario-spa-overview
  EOT
}

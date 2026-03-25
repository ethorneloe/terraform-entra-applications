# Example: Multi-Tenant SaaS Application
#
# Microsoft terminology: "Multi-tenant apps"
# https://learn.microsoft.com/en-us/entra/identity-platform/single-and-multi-tenant-apps
#
# Use case: SaaS applications that serve multiple Azure AD tenants
# Auth flow: Authorization Code + PKCE (OAuth 2.0 / OpenID Connect)
# Sign-in audience: AzureADMultipleOrgs (any Azure AD tenant)
#
# Examples:
# - Multi-tenant SaaS products
# - ISV applications
# - Partner integrations
# - Apps sold via Azure Marketplace

module "saas_platform" {
  source = "../modules/sso-application"

  # Pattern auto-applies multi-tenant defaults:
  # - Sets sign_in_audience = "AzureADMultipleOrgs"
  # - Enforces PKCE (secure authorization code flow)
  # - Disables implicit grant flow
  app_pattern  = "multitenant"
  display_name = "Acme SaaS Platform"
  description  = "Multi-tenant SaaS application for enterprise customers"

  # Web application redirect URIs
  web_redirect_uris = [
    "https://app.acme-saas.com/signin-oidc",
    "https://app.acme-saas.com/auth/callback",
    "https://localhost:5001/signin-oidc" # Local development
  ]

  # API Application ID URI (must be globally unique for multi-tenant)
  # Format: api://{tenant-id}/{app-id} or https://{verified-domain}/{app-name}
  identifier_uris = [
    "https://app.acme-saas.com"
  ]

  # Delegated permissions (user consent)
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
      },
      {
        id   = "14dad69e-099b-42c9-810b-d002981feec1" # profile
        type = "Scope"
      }
    ]
  }]

  # Optional claims for multi-tenant apps
  optional_claims = {
    id_token = [
      { name = "email", essential = true, source = null, additional_properties = null },
      { name = "preferred_username", essential = false, source = null, additional_properties = null }
    ]
    access_token = [
      { name = "tid", essential = true, source = null, additional_properties = null }, # Tenant ID
      { name = "upn", essential = false, source = null, additional_properties = null }  # User Principal Name
    ]
    saml2_token = null
  }

  # Client secret for multi-tenant web app
  create_client_secret   = true
  password_rotation_days = 180

  # App roles for customer tenant assignment
  app_roles = [
    {
      allowed_member_types = ["User"]
      description          = "Administrator role with full access"
      display_name         = "Administrator"
      enabled              = true
      id                   = "11111111-2222-3333-4444-555555555555"
      value                = "Admin"
    },
    {
      allowed_member_types = ["User"]
      description          = "Standard user with read/write access"
      display_name         = "User"
      enabled              = true
      id                   = "22222222-3333-4444-5555-666666666666"
      value                = "User"
    },
    {
      allowed_member_types = ["User"]
      description          = "Read-only access"
      display_name         = "Viewer"
      enabled              = true
      id                   = "33333333-4444-5555-6666-777777777777"
      value                = "Viewer"
    }
  ]

  # Production safety
  prevent_destroy = true
  notes           = "Multi-tenant SaaS platform - Customers across multiple Azure AD tenants"

  tags = local.common_tag_list
}

# ═══════════════════════════════════════════════════════════════════════════
# MULTI-TENANT CONSIDERATIONS
# ═══════════════════════════════════════════════════════════════════════════
#
# 1. ADMIN CONSENT
#    - Admin consent is required in each customer tenant
#    - Provide admin consent URL to customers:
#      https://login.microsoftonline.com/organizations/v2.0/adminconsent
#      ?client_id={client-id}
#      &redirect_uri={redirect-uri}
#      &scope=User.Read openid profile email
#
# 2. TENANT ISOLATION
#    - Store tenant-specific data separately
#    - Use tid (tenant ID) claim to identify customer tenant
#    - Implement tenant-level access controls in your app
#
# 3. PUBLISHER VERIFICATION
#    - Verify your publisher identity in Azure AD
#    - Required for production multi-tenant apps
#    - Builds trust with customer tenants
#    - See: https://learn.microsoft.com/en-us/entra/identity-platform/publisher-verification-overview
#
# 4. SIGN-IN AUDIENCES
#    - AzureADMultipleOrgs: Any Azure AD tenant (this example)
#    - AzureADandPersonalMicrosoftAccount: Azure AD + personal Microsoft accounts
#    - PersonalMicrosoftAccount: Personal Microsoft accounts only
#
# 5. IDENTIFIER URIS
#    - Must be globally unique across all tenants
#    - Use verified custom domain: https://yourdomain.com
#    - Or format: api://{app-id}
#
# 6. USER ASSIGNMENT
#    - In customer tenants, admins control user access
#    - Your app roles define available permissions
#    - Customer admins assign users to roles
#
# ═══════════════════════════════════════════════════════════════════════════

# Outputs for multi-tenant configuration
output "saas_platform_config" {
  description = "Multi-tenant SaaS platform configuration"
  value = {
    tenant_id     = local.tenant_id # Your home tenant
    client_id     = module.saas_platform.application_id
    client_secret = module.saas_platform.client_secret

    # Multi-tenant endpoints
    authority     = "https://login.microsoftonline.com/organizations"
    token_url     = "https://login.microsoftonline.com/organizations/oauth2/v2.0/token"

    # Admin consent URL for customer tenants
    admin_consent_url = "https://login.microsoftonline.com/organizations/v2.0/adminconsent?client_id=${module.saas_platform.application_id}&redirect_uri=https://app.acme-saas.com/auth/callback"
  }
  sensitive = true
}

# Multi-tenant onboarding guide
output "customer_onboarding_guide" {
  description = "Guide for onboarding new customer tenants"
  value = <<-EOT
    ═══════════════════════════════════════════════════════════════════════════
    CUSTOMER TENANT ONBOARDING GUIDE
    ═══════════════════════════════════════════════════════════════════════════

    When a new customer signs up for your SaaS platform:

    1. ADMIN CONSENT (Required for first user in new tenant):

       Send customer admin to:
       https://login.microsoftonline.com/organizations/v2.0/adminconsent
       ?client_id=${module.saas_platform.application_id}
       &redirect_uri=https://app.acme-saas.com/auth/callback
       &scope=User.Read openid profile email

    2. CUSTOMER ADMIN ACTIONS:
       a. Reviews requested permissions
       b. Grants consent for their organization
       c. Assigns users to app roles (Admin, User, Viewer)

    3. YOUR APPLICATION:
       a. Receives admin consent callback
       b. Stores customer tenant ID (tid claim)
       c. Creates tenant-specific database/partition
       d. Enables access for users in that tenant

    4. END USERS:
       - Can now sign in with their Azure AD accounts
       - Inherit permissions based on assigned role
       - No additional consent required (admin already consented)

    5. TENANT IDENTIFICATION:
       - Extract tid (tenant ID) from ID token or access token
       - Use tid to route to correct tenant data
       - Implement tenant isolation in your data layer

    ═══════════════════════════════════════════════════════════════════════════

    📚 Learn more:
    - https://learn.microsoft.com/en-us/entra/identity-platform/howto-convert-app-to-be-multi-tenant
    - https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-multi-tenant-app
  EOT
}

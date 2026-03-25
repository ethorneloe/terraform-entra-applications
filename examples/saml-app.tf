# Example: SAML 2.0 Enterprise Application
#
# Use case: Enterprise SSO for SaaS applications and legacy systems
# Auth flow: SAML 2.0 (XML-based federation)
# Identity Provider (IdP): Azure AD / Entra ID
# Service Provider (SP): Your application or third-party SaaS
#
# Examples:
# - Salesforce, ServiceNow, Workday integration
# - Custom enterprise applications with SAML
# - Legacy applications requiring SAML SSO

module "salesforce_sso" {
  source = "../modules/sso-application"

  # Pattern auto-applies SAML defaults:
  # - Sets preferred_single_sign_on_mode = "saml"
  # - Requires user assignment (app_role_assignment_required = true)
  # - Disables implicit grant
  app_pattern  = "saml"
  display_name = "Salesforce SSO"
  description  = "SAML SSO integration with Salesforce CRM"

  # Application ID URI (Entity ID / Audience URI from SP)
  # This must match the Entity ID in your SAML Service Provider
  identifier_uris = [
    "https://example.my.salesforce.com"
  ]

  # Reply URLs (Assertion Consumer Service URLs from SP)
  web_redirect_uris = [
    "https://example.my.salesforce.com",
    "https://example.my.salesforce.com/services/auth/saml/SSO"
  ]

  # SAML configuration
  saml_single_sign_on = {
    relay_state = "" # Optional: RelayState parameter for deep linking
  }

  # App roles for user assignment
  app_roles = [
    {
      allowed_member_types = ["User"]
      description          = "Salesforce Administrator"
      display_name         = "Admin"
      enabled              = true
      id                   = "aaaaaaaa-bbbb-cccc-dddd-111111111111"
      value                = "Admin"
    },
    {
      allowed_member_types = ["User"]
      description          = "Salesforce Standard User"
      display_name         = "User"
      enabled              = true
      id                   = "aaaaaaaa-bbbb-cccc-dddd-222222222222"
      value                = "User"
    }
  ]

  # SAML apps typically require user assignment for security
  # app_role_assignment_required = true  # Auto-set by pattern

  # Notification emails for certificate expiration
  notification_email_addresses = [
    "identity-team@example.com"
  ]

  # Service management reference (CMDB)
  service_management_reference = "INC0012345"

  # Production safety
  prevent_destroy = true
  notes           = "SAML SSO for Salesforce CRM - Contact: identity-team@example.com"

  # Feature tags
  enterprise_app = true
  hide_app       = false # Show in My Apps portal

  tags = local.common_tag_list
}

# ─────────────────────────────────────────────────────────────────────────────
# CERTIFICATE MANAGEMENT
# ─────────────────────────────────────────────────────────────────────────────
# SAML signing certificates are NOT managed by Terraform (by design).
#
# To configure SAML certificates:
#
# 1. Via Azure Portal:
#    - Go to: Enterprise applications → Salesforce SSO → Single sign-on
#    - Under "SAML Signing Certificate", manage certificates
#    - Azure auto-generates a certificate valid for 3 years
#
# 2. Via Azure CLI:
#    az ad sp create-for-rbac --name "Salesforce SSO" --create-cert
#
# 3. Certificate renewal (before expiration):
#    - Azure Portal: Upload new certificate
#    - Update Service Provider with new certificate metadata
#    - Test SSO before removing old certificate
#    - Delete expired certificate after cutover
#
# 📧 Set notification_email_addresses to get expiration alerts
# ─────────────────────────────────────────────────────────────────────────────

# Assign users/groups to SAML app roles
# Example: Assign "Sales Team" group to "User" role
resource "azuread_app_role_assignment" "salesforce_sales_team" {
  app_role_id         = "aaaaaaaa-bbbb-cccc-dddd-222222222222" # User role
  principal_object_id = "11111111-2222-3333-4444-555555555555" # Sales Team group ID
  resource_object_id  = module.salesforce_sso.service_principal_id
}

# Outputs for SAML configuration
output "salesforce_saml_metadata" {
  description = "SAML metadata for Service Provider configuration"
  value = {
    entity_id                = module.salesforce_sso.application_id_uri
    sso_url                  = "https://login.microsoftonline.com/${local.tenant_id}/saml2"
    logout_url               = "https://login.microsoftonline.com/${local.tenant_id}/saml2"
    certificate_download_url = "https://portal.azure.com/#view/Microsoft_AAD_IAM/ManagedAppMenuBlade/~/SingleSignOn/objectId/${module.salesforce_sso.service_principal_id}"
  }
}

# SAML configuration guide
output "salesforce_setup_guide" {
  description = "Step-by-step SAML configuration guide"
  value = <<-EOT
    ═══════════════════════════════════════════════════════════════════════════
    SAML SSO CONFIGURATION GUIDE - Salesforce
    ═══════════════════════════════════════════════════════════════════════════

    1. DOWNLOAD SAML METADATA FROM AZURE AD:
       a. Go to: https://portal.azure.com → Enterprise applications
       b. Search for: "Salesforce SSO"
       c. Click: Single sign-on → SAML
       d. Download: Federation Metadata XML

    2. CONFIGURE SALESFORCE (Service Provider):
       a. Salesforce Setup → Settings → Identity → Single Sign-On Settings
       b. Click "Edit" and enable SAML
       c. Click "New from Metadata File"
       d. Upload the Federation Metadata XML from step 1
       e. Configure:
          - Name: Azure AD SSO
          - Entity ID: https://example.my.salesforce.com
          - Start URL: https://example.my.salesforce.com

    3. UPDATE AZURE AD WITH SALESFORCE DETAILS:
       - Reply URL: Copy from Salesforce SAML config
       - Sign on URL: https://example.my.salesforce.com
       - Relay State: (optional) for deep linking

    4. ATTRIBUTE MAPPING (Optional):
       Map Azure AD attributes to Salesforce user fields:
       - Email → user.mail
       - First Name → user.givenname
       - Last Name → user.surname

    5. ASSIGN USERS/GROUPS:
       Already configured via Terraform (see app_role_assignment above)

    6. TEST SSO:
       a. Go to: https://myapps.microsoft.com
       b. Click on "Salesforce SSO" tile
       c. Should redirect to Salesforce without re-authentication

    7. CERTIFICATE RENEWAL (Every 3 years):
       - Set reminder 60 days before expiration
       - Generate new certificate in Azure AD
       - Upload to Salesforce
       - Test before removing old certificate

    ═══════════════════════════════════════════════════════════════════════════

    📚 Documentation:
    - https://learn.microsoft.com/en-us/azure/active-directory/saas-apps/salesforce-tutorial
    - https://help.salesforce.com/s/articleView?id=sf.sso_saml.htm

    📧 Questions: identity-team@example.com
  EOT
}

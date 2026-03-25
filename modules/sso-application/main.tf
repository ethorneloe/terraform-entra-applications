# SSO Application Module
# This module creates an Entra ID application registration with service principal,
# API permissions, and optional admin consent

# Pattern-based security defaults
# When app_pattern is set, these defaults are applied for security best practices
locals {
  # Define security defaults for each authentication pattern
  pattern_defaults = var.app_pattern != null ? {
    oidc_web = {
      implicit_grant_enabled     = false # Force authorization code + PKCE
      sign_in_audience          = "AzureADMyOrg"
      preferred_sso_mode        = "oidc"
      app_role_assignment_required = false
    }
    oidc_spa = {
      implicit_grant_enabled     = false # SPAs should use auth code + PKCE
      sign_in_audience          = "AzureADMyOrg"
      preferred_sso_mode        = "oidc"
      app_role_assignment_required = false
    }
    daemon = {
      implicit_grant_enabled     = false # Daemons use client credentials
      sign_in_audience          = "AzureADMyOrg"
      preferred_sso_mode        = null
      app_role_assignment_required = false
    }
    saml = {
      implicit_grant_enabled     = false
      sign_in_audience          = "AzureADMyOrg"
      preferred_sso_mode        = "saml"
      app_role_assignment_required = true # SAML apps typically require assignment
    }
  }[var.app_pattern] : null

  # Apply implicit grant settings based on pattern or explicit config
  implicit_grant_config = var.web_implicit_grant != null ? var.web_implicit_grant : (
    var.require_pkce || local.pattern_defaults != null ? {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = false
    } : null
  )

  # Validation: Ensure only one client type is configured
  client_type_count = (
    (var.web_redirect_uris != null && length(var.web_redirect_uris) > 0 ? 1 : 0) +
    (var.spa_redirect_uris != null && length(var.spa_redirect_uris) > 0 ? 1 : 0) +
    (var.public_client_redirect_uris != null && length(var.public_client_redirect_uris) > 0 ? 1 : 0)
  )

  validate_client_type = local.client_type_count <= 1 ? true : tobool("ERROR: Only one client type (web, spa, or public_client) should have redirect URIs configured")
}

# Create or reference existing application registration
resource "azuread_application" "app" {
  display_name            = var.display_name
  description             = var.description
  sign_in_audience        = var.sign_in_audience
  prevent_duplicate_names = var.prevent_duplicate_names
  owners                  = var.app_owners

  # Application ID URI (for API applications)
  identifier_uris = var.identifier_uris

  # Web application configuration
  dynamic "web" {
    for_each = var.web_redirect_uris != null || local.implicit_grant_config != null ? [1] : []
    content {
      redirect_uris = var.web_redirect_uris

      dynamic "implicit_grant" {
        for_each = local.implicit_grant_config != null ? [local.implicit_grant_config] : []
        content {
          access_token_issuance_enabled = implicit_grant.value.access_token_issuance_enabled
          id_token_issuance_enabled     = implicit_grant.value.id_token_issuance_enabled
        }
      }
    }
  }

  # Single Page Application (SPA) configuration
  dynamic "single_page_application" {
    for_each = var.spa_redirect_uris != null ? [1] : []
    content {
      redirect_uris = var.spa_redirect_uris
    }
  }

  # Public client/native application configuration
  dynamic "public_client" {
    for_each = var.public_client_redirect_uris != null ? [1] : []
    content {
      redirect_uris = var.public_client_redirect_uris
    }
  }

  # API configuration
  dynamic "api" {
    for_each = var.api_oauth2_permission_scopes != null || var.expose_api ? [1] : []
    content {
      mapped_claims_enabled          = var.mapped_claims_enabled
      requested_access_token_version = var.requested_access_token_version

      dynamic "oauth2_permission_scope" {
        for_each = var.api_oauth2_permission_scopes != null ? var.api_oauth2_permission_scopes : []
        content {
          admin_consent_description  = oauth2_permission_scope.value.admin_consent_description
          admin_consent_display_name = oauth2_permission_scope.value.admin_consent_display_name
          enabled                    = oauth2_permission_scope.value.enabled
          id                         = oauth2_permission_scope.value.id
          type                       = oauth2_permission_scope.value.type
          user_consent_description   = oauth2_permission_scope.value.user_consent_description
          user_consent_display_name  = oauth2_permission_scope.value.user_consent_display_name
          value                      = oauth2_permission_scope.value.value
        }
      }
    }
  }

  # App roles
  dynamic "app_role" {
    for_each = var.app_roles != null ? var.app_roles : []
    content {
      allowed_member_types = app_role.value.allowed_member_types
      description          = app_role.value.description
      display_name         = app_role.value.display_name
      enabled              = app_role.value.enabled
      id                   = app_role.value.id
      value                = app_role.value.value
    }
  }

  # Required API permissions
  dynamic "required_resource_access" {
    for_each = var.required_resource_access != null ? var.required_resource_access : []
    content {
      resource_app_id = required_resource_access.value.resource_app_id

      dynamic "resource_access" {
        for_each = required_resource_access.value.resource_access
        content {
          id   = resource_access.value.id
          type = resource_access.value.type
        }
      }
    }
  }

  # Optional claims
  dynamic "optional_claims" {
    for_each = var.optional_claims != null ? [var.optional_claims] : []
    content {
      dynamic "access_token" {
        for_each = optional_claims.value.access_token != null ? optional_claims.value.access_token : []
        content {
          name                  = access_token.value.name
          source                = access_token.value.source
          essential             = access_token.value.essential
          additional_properties = access_token.value.additional_properties
        }
      }

      dynamic "id_token" {
        for_each = optional_claims.value.id_token != null ? optional_claims.value.id_token : []
        content {
          name                  = id_token.value.name
          source                = id_token.value.source
          essential             = id_token.value.essential
          additional_properties = id_token.value.additional_properties
        }
      }

      dynamic "saml2_token" {
        for_each = optional_claims.value.saml2_token != null ? optional_claims.value.saml2_token : []
        content {
          name                  = saml2_token.value.name
          source                = saml2_token.value.source
          essential             = saml2_token.value.essential
          additional_properties = saml2_token.value.additional_properties
        }
      }
    }
  }

  # Group membership claims
  group_membership_claims = var.group_membership_claims

  notes                        = var.notes
  service_management_reference = var.service_management_reference

  tags = var.tags

  lifecycle {
    prevent_destroy = var.prevent_destroy

    # Ignore changes to optional_claims as they may be modified outside Terraform
    ignore_changes = [
      optional_claims,
    ]
  }
}

# Create service principal for the application
resource "azuread_service_principal" "app_sp" {
  client_id = azuread_application.app.client_id
  app_role_assignment_required = (
    local.pattern_defaults != null ?
    local.pattern_defaults.app_role_assignment_required :
    var.app_role_assignment_required
  )
  owners       = var.app_owners
  use_existing = var.use_existing_service_principal

  feature_tags {
    enterprise = var.enterprise_app
    gallery    = var.gallery_app
    hide       = var.hide_app
  }

  # SAML SSO configuration
  dynamic "saml_single_sign_on" {
    for_each = var.saml_single_sign_on != null ? [var.saml_single_sign_on] : []
    content {
      relay_state = saml_single_sign_on.value.relay_state
    }
  }

  # Notification email addresses
  notification_email_addresses = var.notification_email_addresses

  # Preferred single sign-on mode (use pattern default if available)
  preferred_single_sign_on_mode = (
    local.pattern_defaults != null && local.pattern_defaults.preferred_sso_mode != null ?
    local.pattern_defaults.preferred_sso_mode :
    var.preferred_single_sign_on_mode
  )

  tags = concat(var.tags, var.service_principal_tags)

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}

# NOTE: Client secrets managed by Terraform have security implications:
# - Secrets are stored in plain text in the state file
# - Operations are attributed to the service principal instead of the actual operator
# - Secret rotation schedules are security-driven, not infrastructure-driven
# - Emergency rotation shouldn't depend on Terraform pipelines
# - Many compliance frameworks require separation of credential management
#
# Recommended approaches for credential management:
# 1. Use Workload Identity Federation (preferred - no secrets needed)
# 2. Create secrets manually via Entra Admin Center or Azure CLI:
#    az ad app credential reset --id <app-id> --append
# 3. Store secrets in Azure Key Vault and reference them in applications
#
# This resource is provided for convenience but should be used with caution.
resource "azuread_application_password" "app_password" {
  count                 = var.create_client_secret ? 1 : 0
  application_id        = azuread_application.app.id
  display_name          = var.client_secret_display_name
  end_date_relative     = "${var.password_rotation_days * 24}h"
  rotate_when_changed   = var.rotate_secret_when_changed
}

# Admin consent for delegated permissions (type = "Scope")
# NOTE: This resource only handles delegated permissions. For application
# permissions (type = "Role"), use app_role_assignments instead.
resource "azuread_service_principal_delegated_permission_grant" "admin_consent" {
  count                                = var.enable_admin_consent && var.admin_consent_scope != null ? 1 : 0
  service_principal_object_id          = azuread_service_principal.app_sp.object_id
  resource_service_principal_object_id = var.resource_service_principal_object_id
  claim_values                         = var.admin_consent_scope

  lifecycle {
    precondition {
      condition     = var.resource_service_principal_object_id != null
      error_message = "resource_service_principal_object_id must be provided when enable_admin_consent is true and admin_consent_scope is set."
    }
  }
}

# App role assignments to the service principal
# Also serves as the mechanism for granting admin consent to application
# permissions (type = "Role"). Provide one entry per permission to consent.
resource "azuread_app_role_assignment" "app_role_assignment" {
  for_each            = var.app_role_assignments != null ? var.app_role_assignments : {}
  app_role_id         = each.value.app_role_id
  principal_object_id = azuread_service_principal.app_sp.object_id
  resource_object_id  = each.value.resource_object_id
}

# ═══════════════════════════════════════════════════════════════════════════
# CERTIFICATE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════
# Certificates are intentionally NOT managed by Terraform because:
#
# 1. SECURITY: Private keys should never be stored in Terraform state
# 2. COMPLIANCE: Most frameworks require separation of credential management
# 3. OWNERSHIP: Application owners should manage their own certificates
# 4. ROTATION: Certificate renewal is security-driven, not infrastructure-driven
# 5. SCALE: At enterprise scale, centralized cert mgmt creates bottlenecks
#
# ── Recommended Certificate Management Approaches ──
#
# For SAML applications (signing certificates):
#   1. Azure Portal: Enterprise applications → [Your App] → SAML Signing Certificate
#   2. Azure CLI: az ad sp create-for-rbac --name <app> --create-cert
#   3. Let Azure auto-generate certs (default for SAML apps)
#
# For client certificates (authentication):
#   1. Azure Key Vault with automatic rotation
#   2. Manual upload via Entra Admin Center
#   3. Azure CLI: az ad app credential reset --id <app-id> --cert @cert.pem
#
# For modern apps:
#   ✅ PREFERRED: Use Workload Identity Federation (no secrets/certs needed!)
#   See: var.federated_identity_credentials
#
# ═══════════════════════════════════════════════════════════════════════════

# Federation configuration for external identity providers
# Keyed by display_name which must be unique per application; this ensures
# that reordering entries in the list does not cause spurious replacements.
resource "azuread_application_federated_identity_credential" "federated_cred" {
  for_each       = var.federated_identity_credentials != null ? { for v in var.federated_identity_credentials : v.display_name => v } : {}
  application_id = azuread_application.app.id
  display_name   = each.value.display_name
  description    = each.value.description
  audiences      = each.value.audiences
  issuer         = each.value.issuer
  subject        = each.value.subject
}

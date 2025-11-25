# SSO Application Module
# This module creates an Entra ID application registration with service principal,
# API permissions, and optional admin consent

# Validation: Ensure only one client type is configured
locals {
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
  dynamic "identifier_uris" {
    for_each = var.identifier_uris != null ? [1] : []
    content {
      uris = var.identifier_uris
    }
  }

  # Web application configuration
  dynamic "web" {
    for_each = var.web_redirect_uris != null || var.web_implicit_grant != null ? [1] : []
    content {
      redirect_uris = var.web_redirect_uris

      dynamic "implicit_grant" {
        for_each = var.web_implicit_grant != null ? [var.web_implicit_grant] : []
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
  client_id                    = azuread_application.app.client_id
  app_role_assignment_required = var.app_role_assignment_required
  owners                       = var.app_owners
  use_existing                 = var.use_existing_service_principal

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

  # Preferred single sign-on mode
  preferred_single_sign_on_mode = var.preferred_single_sign_on_mode

  tags = concat(var.tags, var.service_principal_tags)

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}

# NOTE: Client secrets are intentionally NOT managed by Terraform for security reasons:
# - Secrets would be stored in plain text in the state file
# - Operations would be attributed to the service principal instead of the actual operator
# - Secret rotation schedules are security-driven, not infrastructure-driven
# - Emergency rotation shouldn't depend on Terraform pipelines
# - Many compliance frameworks require separation of credential management
#
# Recommended approaches for credential management:
# 1. Use Workload Identity Federation (preferred - no secrets needed)
# 2. Create secrets manually via Entra Admin Center or Azure CLI:
#    az ad app credential reset --id <app-id> --append
# 3. Store secrets in Azure Key Vault and reference them in applications

# Admin consent for application permissions
resource "azuread_service_principal_delegated_permission_grant" "admin_consent" {
  count                                = var.enable_admin_consent && var.admin_consent_scope != null ? 1 : 0
  service_principal_object_id          = azuread_service_principal.app_sp.object_id
  resource_service_principal_object_id = var.resource_service_principal_object_id
  claim_values                         = var.admin_consent_scope
}

# App role assignments to the service principal
resource "azuread_app_role_assignment" "app_role_assignment" {
  for_each            = var.app_role_assignments != null ? { for idx, v in var.app_role_assignments : idx => v } : {}
  app_role_id         = each.value.app_role_id
  principal_object_id = azuread_service_principal.app_sp.object_id
  resource_object_id  = each.value.resource_object_id
}

# NOTE: Certificates are intentionally NOT managed by Terraform for security reasons:
# - Certificate private keys should never be in Terraform state
# - Certificate management should be handled by Azure Key Vault with auto-rotation
# - For production use cases, prefer Workload Identity Federation over certificates
#
# If certificates are required, manage them via:
# 1. Azure Key Vault with automatic rotation
# 2. Manual upload via Entra Admin Center
# 3. Azure CLI: az ad app credential reset --id <app-id> --cert @cert.pem

# Federation configuration for external identity providers
resource "azuread_application_federated_identity_credential" "federated_cred" {
  for_each       = var.federated_identity_credentials != null ? { for idx, v in var.federated_identity_credentials : idx => v } : {}
  application_id = azuread_application.app.id
  display_name   = each.value.display_name
  description    = each.value.description
  audiences      = each.value.audiences
  issuer         = each.value.issuer
  subject        = each.value.subject
}

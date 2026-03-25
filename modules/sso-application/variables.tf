# Variables for SSO Application Module

# Application pattern (recommended for best practices)
# Aligned with Microsoft identity platform terminology:
# https://learn.microsoft.com/en-us/entra/identity-platform/v2-app-types
variable "app_pattern" {
  description = <<-EOT
    Application type - applies Microsoft-recommended security defaults:
    - web_app: Web applications (confidential client with server-side code)
    - spa: Single-page applications (public client, browser-based)
    - service: Services/daemons (confidential client, no user interaction)
    - mobile: Mobile and desktop apps (public client, native apps)
    - saml: SAML-based enterprise SSO
    - multitenant: Multi-tenant SaaS applications (any audience)
    Set to null for manual configuration.
  EOT
  type        = string
  default     = null
  validation {
    condition     = var.app_pattern == null || contains(["web_app", "spa", "service", "mobile", "saml", "multitenant"], var.app_pattern)
    error_message = "Must be one of: web_app, spa, service, mobile, saml, multitenant, or null for manual configuration"
  }
}

# Basic application properties
variable "display_name" {
  description = "The display name for the application"
  type        = string
}

variable "description" {
  description = "A description of the application"
  type        = string
  default     = null
}

variable "sign_in_audience" {
  description = "The Microsoft account types supported (AzureADMyOrg, AzureADMultipleOrgs, AzureADandPersonalMicrosoftAccount, PersonalMicrosoftAccount)"
  type        = string
  default     = "AzureADMyOrg"
  validation {
    condition     = contains(["AzureADMyOrg", "AzureADMultipleOrgs", "AzureADandPersonalMicrosoftAccount", "PersonalMicrosoftAccount"], var.sign_in_audience)
    error_message = "Must be one of: AzureADMyOrg, AzureADMultipleOrgs, AzureADandPersonalMicrosoftAccount, PersonalMicrosoftAccount"
  }
}

variable "prevent_duplicate_names" {
  description = "Prevent duplicate application names in the directory"
  type        = bool
  default     = true
}

variable "app_owners" {
  description = "List of user object IDs to set as application owners"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A list of tags to apply to the application"
  type        = list(string)
  default     = []
}

variable "service_principal_tags" {
  description = "Additional tags to apply to the service principal"
  type        = list(string)
  default     = []
}

variable "notes" {
  description = "Notes/description visible in the Azure portal"
  type        = string
  default     = null
}

variable "service_management_reference" {
  description = "Reference to a service or asset management database"
  type        = string
  default     = null
}

variable "prevent_destroy" {
  description = "Prevent accidental destruction of the application and service principal. Set to true for production."
  type        = bool
  default     = false
}

# Application URIs
variable "identifier_uris" {
  description = "A list of user-defined URI(s) that uniquely identify the application"
  type        = list(string)
  default     = null
}

# Web application configuration
variable "web_redirect_uris" {
  description = "A list of redirect URIs for web applications"
  type        = list(string)
  default     = null
}

variable "web_implicit_grant" {
  description = "Implicit grant settings for web applications. SECURITY WARNING: Implicit flow is deprecated. Use authorization code flow with PKCE instead."
  type = object({
    access_token_issuance_enabled = bool
    id_token_issuance_enabled     = bool
  })
  default = null
}

variable "require_pkce" {
  description = "Enforce PKCE (Proof Key for Code Exchange) for authorization code flow. Recommended for all modern apps. Disables implicit grant flow when true."
  type        = bool
  default     = true
}

# SPA configuration
variable "spa_redirect_uris" {
  description = "A list of redirect URIs for single page applications"
  type        = list(string)
  default     = null
}

# Public client configuration
variable "public_client_redirect_uris" {
  description = "A list of redirect URIs for public client/native applications"
  type        = list(string)
  default     = null
}

# API configuration
variable "expose_api" {
  description = "Whether to expose the application as an API"
  type        = bool
  default     = false
}

variable "mapped_claims_enabled" {
  description = "Whether mapped claims are enabled for the API"
  type        = bool
  default     = false
}

variable "requested_access_token_version" {
  description = "The access token version expected by the API (1 or 2)"
  type        = number
  default     = 2
  validation {
    condition     = contains([1, 2], var.requested_access_token_version)
    error_message = "Must be 1 or 2"
  }
}

variable "api_oauth2_permission_scopes" {
  description = "OAuth2 permission scopes exposed by the API"
  type = list(object({
    admin_consent_description  = string
    admin_consent_display_name = string
    enabled                    = bool
    id                         = string
    type                       = string
    user_consent_description   = string
    user_consent_display_name  = string
    value                      = string
  }))
  default = null
}

# App roles
variable "app_roles" {
  description = "App roles to be assigned to users, groups, or service principals"
  type = list(object({
    allowed_member_types = list(string)
    description          = string
    display_name         = string
    enabled              = bool
    id                   = string
    value                = string
  }))
  default = null
}

# Required API permissions
variable "required_resource_access" {
  description = "API permissions required by the application"
  type = list(object({
    resource_app_id = string
    resource_access = list(object({
      id   = string
      type = string
    }))
  }))
  default = null
}

# Optional claims
variable "optional_claims" {
  description = "Optional claims to include in tokens"
  type = object({
    access_token = optional(list(object({
      name                  = string
      source                = optional(string)
      essential             = optional(bool)
      additional_properties = optional(list(string))
    })))
    id_token = optional(list(object({
      name                  = string
      source                = optional(string)
      essential             = optional(bool)
      additional_properties = optional(list(string))
    })))
    saml2_token = optional(list(object({
      name                  = string
      source                = optional(string)
      essential             = optional(bool)
      additional_properties = optional(list(string))
    })))
  })
  default = null
}

# Group membership claims
variable "group_membership_claims" {
  description = "Configures the groups claim issued in tokens (All, None, ApplicationGroup, DirectoryRole, SecurityGroup)"
  type        = list(string)
  default     = null
}

# Service principal configuration
variable "app_role_assignment_required" {
  description = "Whether user assignment is required for this service principal"
  type        = bool
  default     = false
}

variable "use_existing_service_principal" {
  description = "Use an existing service principal if one already exists for this application"
  type        = bool
  default     = false
}

variable "notification_email_addresses" {
  description = "Email addresses to notify about certificate expiration and service principal issues"
  type        = list(string)
  default     = []
}

variable "preferred_single_sign_on_mode" {
  description = "The single sign-on mode (saml, password, notSupported)"
  type        = string
  default     = null
  validation {
    condition     = var.preferred_single_sign_on_mode == null || contains(["saml", "password", "notSupported", "oidc"], var.preferred_single_sign_on_mode)
    error_message = "Must be one of: saml, password, notSupported, oidc, or null"
  }
}

variable "enterprise_app" {
  description = "Whether this is an enterprise application (appears in My Apps)"
  type        = bool
  default     = true
}

variable "gallery_app" {
  description = "Whether this application is from the Azure AD app gallery"
  type        = bool
  default     = false
}

variable "hide_app" {
  description = "Whether to hide this application from My Apps and Office 365 app launcher"
  type        = bool
  default     = false
}

# SAML configuration
variable "saml_single_sign_on" {
  description = "SAML single sign-on configuration"
  type = object({
    relay_state = string
  })
  default = null
}

# Client secret configuration
variable "create_client_secret" {
  description = "Whether to create a client secret for the application"
  type        = bool
  default     = true
}

variable "client_secret_display_name" {
  description = "Display name for the client secret"
  type        = string
  default     = "Terraform Managed Secret"
}

variable "password_rotation_days" {
  description = "Number of days before the client secret expires"
  type        = number
  default     = 180
}

variable "rotate_secret_when_changed" {
  description = "Map of values that will trigger secret rotation when changed"
  type        = map(string)
  default     = {}
}

# NOTE: Certificate management is intentionally NOT supported in this module.
# Certificates should be managed by application owners via Azure Portal, CLI, or Key Vault.
# For modern authentication, use Workload Identity Federation (federated_identity_credentials) instead.

# Admin consent configuration
variable "enable_admin_consent" {
  description = "Whether to grant admin consent for delegated permissions"
  type        = bool
  default     = false
}

variable "admin_consent_scope" {
  description = "The delegated permission scopes to consent to"
  type        = list(string)
  default     = null
}

variable "resource_service_principal_object_id" {
  description = "The object ID of the resource service principal (e.g., Microsoft Graph) for admin consent"
  type        = string
  default     = null
}

# App role assignments
variable "app_role_assignments" {
  description = "App role assignments for the service principal. Map keys are arbitrary identifiers."
  type = map(object({
    app_role_id        = string
    resource_object_id = string
  }))
  default = null
}

# Federated identity credentials (for workload identity federation)
variable "federated_identity_credentials" {
  description = "Federated identity credentials for external identity providers (e.g., GitHub Actions, Kubernetes)"
  type = list(object({
    display_name = string
    description  = string
    audiences    = list(string)
    issuer       = string
    subject      = string
  }))
  default = null
}

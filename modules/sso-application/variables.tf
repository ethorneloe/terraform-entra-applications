# Variables for SSO Application Module

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
  description = "Implicit grant settings for web applications"
  type = object({
    access_token_issuance_enabled = bool
    id_token_issuance_enabled     = bool
  })
  default = null
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

# Certificate configuration
variable "certificate_value" {
  description = "The certificate value (PEM format)"
  type        = string
  default     = null
  sensitive   = true
}

variable "certificate_type" {
  description = "The certificate type (AsymmetricX509Cert or Symmetric)"
  type        = string
  default     = "AsymmetricX509Cert"
}

variable "certificate_end_date" {
  description = "The end date until which the certificate is valid (RFC3339 format)"
  type        = string
  default     = null
}

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
  description = "App role assignments for the service principal"
  type = list(object({
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

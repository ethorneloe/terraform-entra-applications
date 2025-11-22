# Environment-level variables for SSO application management

variable "environment" {
  description = "The deployment environment (dev, test, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, prod"
  }
}

variable "tenant_domain" {
  description = "The primary domain name for the Entra ID tenant (e.g., contoso.onmicrosoft.com)"
  type        = string
}

variable "app_owners" {
  description = "List of user principal names or object IDs to set as owners for all applications"
  type        = list(string)
  default     = []
}

variable "enable_admin_consent" {
  description = "Automatically grant admin consent for application API permissions"
  type        = bool
  default     = false
}

variable "certificate_path" {
  description = "Optional path to certificate file for application authentication"
  type        = string
  default     = null
}

variable "certificate_password" {
  description = "Password for the certificate file (if encrypted)"
  type        = string
  default     = null
  sensitive   = true
}

variable "password_rotation_days" {
  description = "Number of days before application passwords/secrets expire"
  type        = number
  default     = 180
  validation {
    condition     = var.password_rotation_days >= 1 && var.password_rotation_days <= 730
    error_message = "Password rotation days must be between 1 and 730 (2 years)"
  }
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "use_existing_service_principals" {
  description = "Map of application names to existing service principal object IDs to import"
  type        = map(string)
  default     = {}
}

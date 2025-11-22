# Production Environment Configuration

environment    = "prod"
tenant_domain  = "yourcompany.onmicrosoft.com"

# Application owners (use actual user object IDs or UPNs)
app_owners = [
  # "user1@yourcompany.onmicrosoft.com",
  # "user2@yourcompany.onmicrosoft.com"
]

# Admin consent settings (typically enabled in production after validation)
enable_admin_consent = true

# Password/secret rotation (longer rotation for production)
password_rotation_days = 180

# Common tags for all applications
tags = {
  CostCenter  = "Engineering"
  Department  = "IT"
  Project     = "SSO Integration"
  Owner       = "Platform Team"
  Environment = "Production"
  Compliance  = "Required"
}

# Existing service principals to import (if any)
use_existing_service_principals = {
  # "app-name" = "existing-sp-object-id"
}

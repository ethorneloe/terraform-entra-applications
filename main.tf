# Shared data sources and locals
# This file contains shared configuration used across all SSO application modules

# Data source for current Entra ID client configuration
data "azuread_client_config" "current" {}

# Data source for Microsoft Graph service principal
data "azuread_service_principal" "microsoft_graph" {
  client_id = "00000003-0000-0000-c000-000000000000"
}

# Local values used across all SSO application configurations
locals {
  # Common metadata
  tenant_id = data.azuread_client_config.current.tenant_id

  # Common tags to apply to all resources
  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "terraform-entra-applications"
    },
    var.tags
  )

  # Common redirect URIs for SSO applications
  common_redirect_uris = {
    web = [
      "https://login.microsoftonline.com/common/oauth2/nativeclient",
      "https://login.live.com/oauth20_desktop.srf"
    ]
    spa = [
      "http://localhost:3000",
      "http://localhost:8080"
    ]
  }
}

# Individual SSO application configurations are defined in separate files:
# - app_registration_example.tf (for custom app registrations)
# - gallery_app_example.tf (for marketplace/gallery apps)
# Each file calls the ./modules/sso-application module with specific configurations

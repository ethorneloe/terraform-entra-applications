# Shared data sources and locals
# This file contains shared configuration used across all SSO application modules

# Data source for current Entra ID client configuration
data "azuread_client_config" "current" {}

# Data source for Microsoft Graph service principal
# The well-known client ID for Microsoft Graph is stable across all tenants.
data "azuread_service_principal" "microsoft_graph" {
  client_id = "00000003-0000-0000-c000-000000000000"
}

# Local values used across all SSO application configurations
locals {
  # Common metadata
  tenant_id = data.azuread_client_config.current.tenant_id

  # Microsoft Graph - centralised so all app files reference these locals
  # instead of repeating the hardcoded GUIDs.
  microsoft_graph_app_id       = "00000003-0000-0000-c000-000000000000"
  microsoft_graph_sp_object_id = data.azuread_service_principal.microsoft_graph.object_id

  # Common tags applied to every resource.
  # The azuread provider expects tags as a list of strings; the conventional
  # format is "Key:Value" which is what the for-expression below produces.
  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "terraform-entra-applications"
    },
    var.tags
  )

  # Pre-built tag list derived from common_tags for direct use in module calls.
  common_tag_list = [for k, v in local.common_tags : "${k}:${v}"]
}

# Individual SSO application configurations are defined in separate files:
# - app_registration_example.tf (for custom app registrations)
# - gallery_app_example.tf (for marketplace/gallery apps)
# Each file calls the ./modules/sso-application module with specific configurations

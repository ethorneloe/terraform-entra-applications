# Example: Service / Daemon Application
#
# Microsoft terminology: "Daemons and server-side apps" (confidential client)
# https://learn.microsoft.com/en-us/entra/identity-platform/v2-app-types#services-and-server-side-apps
#
# Use case: Background services, scheduled jobs, API-to-API communication
# Auth flow: Client Credentials (OAuth 2.0)
# No user interaction - service authenticates as itself using its own identity
#
# Examples:
# - Nightly data sync jobs
# - Monitoring/alerting services
# - Backend API services
# - CI/CD pipelines (when not using Workload Identity Federation)
# - Microservices calling other APIs

module "monitoring_service" {
  source = "../modules/sso-application"

  # Pattern auto-applies security defaults for service applications
  app_pattern  = "service"
  display_name = "Monitoring Service"
  description  = "Background service for system monitoring and alerting"

  # Service apps don't have redirect URIs (no user login)
  # web_redirect_uris = null
  # spa_redirect_uris = null

  # Application permissions (acts as itself, not on behalf of a user)
  required_resource_access = [{
    resource_app_id = local.microsoft_graph_app_id
    resource_access = [
      # Example: Application permissions (type = "Role")
      {
        id   = "df021288-bdef-4463-88db-98f22de89214" # User.Read.All
        type = "Role"                                  # Application permission
      },
      {
        id   = "b0afded3-3588-46d8-8b3d-9842eff778da" # AuditLog.Read.All
        type = "Role"
      }
    ]
  }]

  # Modern alternative: Use Workload Identity Federation (no secrets!)
  # Recommended for GitHub Actions, Azure DevOps, Kubernetes
  federated_identity_credentials = [
    {
      display_name = "github-actions-prod"
      description  = "GitHub Actions workflow in production"
      audiences    = ["api://AzureADTokenExchange"]
      issuer       = "https://token.actions.githubusercontent.com"
      subject      = "repo:yourorg/yourrepo:environment:production"
    }
  ]

  # If using client secret (NOT recommended - use federated identity instead)
  create_client_secret   = false # Set to true only if absolutely necessary
  password_rotation_days = 90    # Short rotation for security

  # Security settings
  prevent_destroy = true # Prevent accidental deletion in production

  tags = local.common_tag_list
}

# Admin consent for application permissions
# Required for service apps to function
resource "azuread_app_role_assignment" "monitoring_service_graph" {
  app_role_id         = "df021288-bdef-4463-88db-98f22de89214" # User.Read.All
  principal_object_id = module.monitoring_service.service_principal_id
  resource_object_id  = local.microsoft_graph_sp_object_id
}

# Output credentials for use in application configuration
output "monitoring_service_credentials" {
  description = "Credentials for monitoring service"
  value = {
    tenant_id      = local.tenant_id
    client_id      = module.monitoring_service.application_id
    client_secret  = module.monitoring_service.client_secret
  }
  sensitive = true
}

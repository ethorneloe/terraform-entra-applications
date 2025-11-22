# Example: Workload Identity Federation for GitHub Actions
# This example demonstrates creating an application with federated credentials for passwordless authentication

module "github_actions_identity" {
  source = "./modules/sso-application"

  # Basic application properties
  display_name     = "GitHub Actions Workload Identity - ${var.environment}"
  description      = "Federated identity for GitHub Actions workflows using OIDC"
  sign_in_audience = "AzureADMyOrg"
  app_owners       = var.app_owners
  tags             = concat(["WorkloadIdentity", "GitHubActions", "Example"], [for k, v in local.common_tags : "${k}:${v}"])

  # API permissions - Adjust based on what GitHub Actions needs to do
  required_resource_access = [
    {
      # Microsoft Graph
      resource_app_id = "00000003-0000-0000-c000-000000000000"
      resource_access = [
        {
          # Application.Read.All - Application permission
          id   = "9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30"
          type = "Role"
        }
      ]
    }
  ]

  # Service principal configuration
  app_role_assignment_required = false

  # No client secret needed - using federated credentials
  create_client_secret = false

  # Federated identity credentials for GitHub Actions
  federated_identity_credentials = [
    {
      display_name = "GitHub Actions - Main Branch"
      description  = "Federated credential for GitHub Actions running on main branch"
      audiences    = ["api://AzureADTokenExchange"]
      issuer       = "https://token.actions.githubusercontent.com"
      subject      = "repo:your-org/your-repo:ref:refs/heads/main"
    },
    {
      display_name = "GitHub Actions - Pull Requests"
      description  = "Federated credential for GitHub Actions pull request workflows"
      audiences    = ["api://AzureADTokenExchange"]
      issuer       = "https://token.actions.githubusercontent.com"
      subject      = "repo:your-org/your-repo:pull_request"
    },
    {
      display_name = "GitHub Actions - Environment"
      description  = "Federated credential for specific GitHub environment"
      audiences    = ["api://AzureADTokenExchange"]
      issuer       = "https://token.actions.githubusercontent.com"
      subject      = "repo:your-org/your-repo:environment:production"
    }
  ]
}

# Example: Workload Identity for Azure Kubernetes Service (AKS)
module "aks_workload_identity" {
  source = "./modules/sso-application"

  # Basic application properties
  display_name     = "AKS Workload Identity - ${var.environment}"
  description      = "Federated identity for AKS workloads using OIDC"
  sign_in_audience = "AzureADMyOrg"
  app_owners       = var.app_owners
  tags             = concat(["WorkloadIdentity", "AKS", "Example"], [for k, v in local.common_tags : "${k}:${v}"])

  # API permissions - Adjust based on workload requirements
  required_resource_access = [
    {
      # Microsoft Graph
      resource_app_id = "00000003-0000-0000-c000-000000000000"
      resource_access = [
        {
          # User.Read.All - Application permission
          id   = "df021288-bdef-4463-88db-98f22de89214"
          type = "Role"
        }
      ]
    }
  ]

  # Service principal configuration
  app_role_assignment_required = false

  # No client secret needed
  create_client_secret = false

  # Federated identity credentials for AKS
  federated_identity_credentials = [
    {
      display_name = "AKS Workload - Namespace App"
      description  = "Federated credential for AKS service account"
      audiences    = ["api://AzureADTokenExchange"]
      issuer       = "https://oidc.prod-aks.azure.com/your-tenant-id/your-aks-oidc-issuer-id/"
      subject      = "system:serviceaccount:your-namespace:your-service-account"
    }
  ]
}

# Outputs for GitHub Actions identity
output "github_actions_application_id" {
  description = "Application (client) ID for GitHub Actions Workload Identity"
  value       = module.github_actions_identity.application_id
}

output "github_actions_federated_credentials" {
  description = "Federated credential IDs for GitHub Actions"
  value       = module.github_actions_identity.federated_identity_credential_ids
}

# Outputs for AKS identity
output "aks_workload_application_id" {
  description = "Application (client) ID for AKS Workload Identity"
  value       = module.aks_workload_identity.application_id
}

output "aks_workload_federated_credentials" {
  description = "Federated credential IDs for AKS"
  value       = module.aks_workload_identity.federated_identity_credential_ids
}

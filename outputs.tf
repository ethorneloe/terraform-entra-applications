# Outputs for all SSO applications
# This file contains shared outputs and placeholders for application-specific outputs

# Shared infrastructure outputs
output "tenant_id" {
  description = "Entra ID Tenant ID"
  value       = local.tenant_id
}

output "microsoft_graph_sp_id" {
  description = "Microsoft Graph Service Principal Object ID"
  value       = data.azuread_service_principal.microsoft_graph.object_id
}

output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

# Note: As new SSO applications are added, create specific outputs in separate sections below
# Example structure:
#
# # App Registration Example Outputs
# output "app_example_application_id" {
#   description = "Application (client) ID for Example App"
#   value       = module.app_example.application_id
# }
#
# output "app_example_service_principal_id" {
#   description = "Service Principal Object ID for Example App"
#   value       = module.app_example.service_principal_id
# }
#
# output "app_example_client_secret" {
#   description = "Client Secret for Example App (sensitive)"
#   value       = module.app_example.client_secret
#   sensitive   = true
# }

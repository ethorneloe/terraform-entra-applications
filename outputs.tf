# Shared infrastructure outputs

output "tenant_id" {
  description = "Entra ID Tenant ID"
  value       = local.tenant_id
}

output "microsoft_graph_sp_id" {
  description = "Microsoft Graph Service Principal Object ID"
  value       = local.microsoft_graph_sp_object_id
}

output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

# Application-specific outputs are co-located with each app file:
#   app_web_api_example.tf   -> web_api_example_* outputs
#   app_spa_example.tf       -> spa_example_* outputs
#   app_daemon_service.tf    -> daemon_service_* outputs
#   app_workload_identity.tf -> github_actions_* / aks_workload_* outputs
#
# When adding a new application file, define its outputs in that same file
# following the naming convention: <app_key>_<output_name>.

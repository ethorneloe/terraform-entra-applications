# Example: Daemon/Service Application
# This example demonstrates creating a background service application with application permissions and certificate authentication

module "daemon_service" {
  source = "./modules/sso-application"

  # Basic application properties
  display_name     = "Example Daemon Service - ${var.environment}"
  description      = "Example background service application using certificate-based authentication"
  sign_in_audience = "AzureADMyOrg"
  app_owners       = var.app_owners
  tags             = concat(["Daemon", "Service", "Example"], [for k, v in local.common_tags : "${k}:${v}"])

  # No redirect URIs for daemon applications

  # API permissions - Application permissions only (no user context)
  required_resource_access = [
    {
      # Microsoft Graph
      resource_app_id = "00000003-0000-0000-c000-000000000000"
      resource_access = [
        {
          # User.Read.All - Application permission
          id   = "df021288-bdef-4463-88db-98f22de89214"
          type = "Role"
        },
        {
          # Group.Read.All - Application permission
          id   = "5b567255-7703-4780-807c-7be8301ae99b"
          type = "Role"
        },
        {
          # Mail.Send - Application permission
          id   = "b633e1c5-b582-4048-a93e-9f11b44c7e96"
          type = "Role"
        },
        {
          # Directory.Read.All - Application permission
          id   = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"
          type = "Role"
        }
      ]
    }
  ]

  # Service principal configuration
  app_role_assignment_required  = false
  preferred_single_sign_on_mode = "oidc"
  notification_email_addresses  = ["serviceadmin@${var.tenant_domain}"]

  # Create client secret (in production, use certificate instead)
  create_client_secret       = true
  client_secret_display_name = "Daemon Service Secret"
  password_rotation_days     = var.password_rotation_days

  # Certificate-based authentication (uncomment and provide certificate value)
  # certificate_value    = var.certificate_path != null ? file(var.certificate_path) : null
  # certificate_type     = "AsymmetricX509Cert"
  # certificate_end_date = timeadd(timestamp(), "8760h") # 1 year from now

  # Admin consent required for application permissions
  enable_admin_consent = var.enable_admin_consent
  # Note: Application permissions require admin consent grant via Portal or PowerShell
  # as azuread_service_principal_delegated_permission_grant only works for delegated permissions

  # App role assignments (if this service needs to call other APIs)
  # app_role_assignments = [
  #   {
  #     app_role_id        = "some-app-role-id"
  #     resource_object_id = "target-service-principal-object-id"
  #   }
  # ]
}

# Output the application details
output "daemon_service_application_id" {
  description = "Application (client) ID for Daemon Service"
  value       = module.daemon_service.application_id
}

output "daemon_service_service_principal_id" {
  description = "Service Principal Object ID for Daemon Service"
  value       = module.daemon_service.service_principal_id
}

output "daemon_service_client_secret" {
  description = "Client Secret for Daemon Service (sensitive)"
  value       = module.daemon_service.client_secret
  sensitive   = true
}

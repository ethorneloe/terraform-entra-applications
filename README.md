# Terraform Entra ID SSO Application Management

A comprehensive Terraform module for managing Single Sign-On (SSO) applications in Microsoft Entra ID (formerly Azure AD). This repository provides infrastructure-as-code solutions for creating, configuring, and managing:

- Custom application registrations
- Marketplace/gallery applications
- Service principals
- API permissions and consent management
- Workload identity federation for GitHub Actions and Kubernetes (passwordless authentication)

## Features

- **Modular Design**: Reusable module for consistent application configuration
- **Workload Identity Federation**: Native support for passwordless authentication with GitHub Actions and AKS (recommended)
- **API Permissions Management**: Simplified configuration of Microsoft Graph and custom API permissions
- **Admin Consent Automation**: Built-in support for delegated permission consent
- **Environment Separation**: Separate configurations for dev, test, and production
- **Security-First**: Client secrets and certificates are managed outside Terraform for enhanced security
- **Best Practices**: Follows Entra ID security and governance best practices
- **Lifecycle Management**: Prevents accidental destruction of production applications
- **Input Validation**: Comprehensive validation of configuration values

## Repository Structure

```
.
├── providers.tf                    # Terraform and provider configuration
├── main.tf                         # Shared data sources and locals
├── variables.tf                    # Environment-level variables
├── outputs.tf                      # Shared outputs
├── app_web_api_example.tf          # Example: Web API application
├── app_spa_example.tf              # Example: Single Page Application
├── app_daemon_service.tf           # Example: Daemon/background service
├── app_workload_identity.tf        # Example: Workload identity federation
├── modules/
│   └── sso-application/            # Reusable SSO application module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── env/
    ├── dev/
    │   └── dev.tfvars              # Development environment variables
    ├── test/
    │   └── test.tfvars             # Test environment variables
    └── prod/
        └── prod.tfvars             # Production environment variables
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.9
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.50.0
- Entra ID tenant with appropriate permissions
- Required Entra ID roles:
  - Application Administrator or Global Administrator
  - Cloud Application Administrator (for admin consent)

## Getting Started

### 1. Authentication

Authenticate to Azure and Entra ID:

```bash
az login --tenant YOUR_TENANT_ID
```

### 2. Configure Backend

Update `providers.tf` with your Azure Storage backend configuration:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatexxxxxx"
    container_name       = "tfstate"
    key                  = "entra-applications.tfstate"
  }
}
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Configure Environment Variables

Edit the appropriate `.tfvars` file in the `env/` directory:

```bash
# For development
cp env/dev/dev.tfvars env/dev/dev.tfvars.local
# Edit env/dev/dev.tfvars.local with your values
```

Key variables to configure:
- `tenant_domain`: Your Entra ID tenant domain
- `app_owners`: List of user object IDs or UPNs who will own the applications
- `enable_admin_consent`: Whether to automatically grant admin consent

### 5. Plan and Apply

```bash
# Plan the deployment
terraform plan -var-file=env/dev/dev.tfvars.local

# Apply the configuration
terraform apply -var-file=env/dev/dev.tfvars.local
```

## Credential Management

**IMPORTANT:** This module intentionally does NOT manage client secrets or certificates within Terraform.

### Why Secrets Aren't Managed by Terraform

Managing secrets in Terraform creates significant security risks:
- **State File Exposure**: Secrets are stored in plain text in Terraform state files
- **Audit Trail Gaps**: Operations are attributed to the service principal, not the actual operator
- **Operational Mismatch**: Secret rotation schedules should be security-driven, not infrastructure-driven
- **Break-Glass Limitations**: Emergency rotation shouldn't depend on Terraform pipelines
- **Compliance Issues**: Many frameworks require separation of credential management

### Recommended Approaches

#### 1. Workload Identity Federation (Preferred)

Use federated credentials to eliminate secrets entirely:

```hcl
module "my_app" {
  source = "./modules/sso-application"

  display_name = "My Application"

  federated_identity_credentials = [
    {
      display_name = "GitHub Actions - Main"
      description  = "For CI/CD pipeline"
      audiences    = ["api://AzureADTokenExchange"]
      issuer       = "https://token.actions.githubusercontent.com"
      subject      = "repo:owner/repo:ref:refs/heads/main"
    }
  ]
}
```

#### 2. Manual Secret Management (When Required)

For legacy applications that require secrets:

**Create the application with Terraform:**
```bash
terraform apply -var-file=env/dev/dev.tfvars.local
```

**Add secrets manually:**
```bash
# Via Azure CLI
az ad app credential reset --id <application-id> --append

# Via Azure Portal
# Navigate to: Entra ID > App registrations > Your App > Certificates & secrets
```

**Store secrets securely:**
- Production: Use Azure Key Vault with RBAC
- Development: Use environment variables (never commit to git)

#### 3. Certificate-Based Authentication

For applications requiring certificates, use Azure Key Vault:
- Store certificates in Azure Key Vault
- Enable automatic rotation
- Reference from Key Vault in your applications

### Credentials in GitHub Actions

Example using federated credentials (no secrets needed):

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## Usage Examples

### Web API Application

Create a web API application with Microsoft Graph permissions:

```hcl
module "my_web_api" {
  source = "./modules/sso-application"

  display_name     = "My Web API - ${var.environment}"
  description      = "Custom web API application"
  sign_in_audience = "AzureADMyOrg"

  identifier_uris = ["api://my-web-api-${var.environment}"]

  web_redirect_uris = [
    "https://myapi.example.com/auth/callback"
  ]

  required_resource_access = [
    {
      resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
      resource_access = [
        {
          id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
          type = "Scope"
        }
      ]
    }
  ]

  # Note: Client secrets should be created manually after Terraform creates the application
  # See "Credential Management" section for details
}
```

### Single Page Application (SPA)

Create a SPA using PKCE authentication:

```hcl
module "my_spa" {
  source = "./modules/sso-application"

  display_name = "My SPA - ${var.environment}"
  description  = "Single Page Application using PKCE authentication"

  spa_redirect_uris = [
    "http://localhost:3000",
    "https://myapp.example.com"
  ]

  required_resource_access = [
    {
      resource_app_id = "00000003-0000-0000-c000-000000000000"
      resource_access = [
        {
          id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
          type = "Scope"
        }
      ]
    }
  ]

  # SPAs use PKCE flow - no client secrets needed
}
```

### Daemon/Service Application

Create a background service with application permissions:

```hcl
module "my_service" {
  source = "./modules/sso-application"

  display_name     = "My Background Service - ${var.environment}"
  description      = "Daemon application with application permissions"
  sign_in_audience = "AzureADMyOrg"

  required_resource_access = [
    {
      resource_app_id = "00000003-0000-0000-c000-000000000000"
      resource_access = [
        {
          id   = "df021288-bdef-4463-88db-98f22de89214" # User.Read.All (Application)
          type = "Role"
        }
      ]
    }
  ]

  # Note: For daemon apps, consider using Workload Identity Federation instead of secrets
  # If secrets are required, create them manually after Terraform deployment
  # For certificate authentication, upload certificates via Azure Key Vault
}
```

### GitHub Actions Workload Identity

Create a passwordless authentication for GitHub Actions:

```hcl
module "github_actions" {
  source = "./modules/sso-application"

  display_name = "GitHub Actions - ${var.environment}"
  description  = "Passwordless authentication for GitHub Actions workflows"

  # Workload Identity Federation - No secrets needed!
  federated_identity_credentials = [
    {
      display_name = "GitHub Actions - Main Branch"
      description  = "Federated credential for main branch workflows"
      audiences    = ["api://AzureADTokenExchange"]
      issuer       = "https://token.actions.githubusercontent.com"
      subject      = "repo:my-org/my-repo:ref:refs/heads/main"
    },
    {
      display_name = "GitHub Actions - Production Environment"
      description  = "Federated credential for production deployments"
      audiences    = ["api://AzureADTokenExchange"]
      issuer       = "https://token.actions.githubusercontent.com"
      subject      = "repo:my-org/my-repo:environment:production"
    }
  ]

  required_resource_access = [
    {
      resource_app_id = "00000003-0000-0000-c000-000000000000"
      resource_access = [
        {
          id   = "9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30" # Application.Read.All
          type = "Role"
        }
      ]
    }
  ]
}
```

## Common Microsoft Graph Permission IDs

### Delegated Permissions (Scope)

| Permission | ID | Description |
|------------|-----|-------------|
| User.Read | `e1fe6dd8-ba31-4d61-89e7-88639da4683d` | Sign in and read user profile |
| User.ReadWrite | `b4e74841-8e56-480b-be8b-910348b18b4c` | Read and update user profile |
| Mail.Read | `570282fd-fa5c-430d-a7fd-fc8dc98a9dca` | Read user mail |
| Mail.Send | `e383f46e-2787-4529-855e-0e479a3ffac0` | Send mail as a user |
| Calendars.Read | `465a38f9-76ea-45b9-9f34-9e8b0d4b0b42` | Read user calendars |
| Files.Read.All | `df85f4d6-205c-4ac5-a5ea-6bf408dba283` | Read all files user can access |

### Application Permissions (Role)

| Permission | ID | Description |
|------------|-----|-------------|
| User.Read.All | `df021288-bdef-4463-88db-98f22de89214` | Read all users' full profiles |
| User.ReadWrite.All | `741f803b-c850-494e-b5df-cde7c675a1ca` | Read and write all users' full profiles |
| Group.Read.All | `5b567255-7703-4780-807c-7be8301ae99b` | Read all groups |
| Directory.Read.All | `7ab1d382-f21e-4acd-a863-ba3e13f7da61` | Read directory data |
| Mail.Send | `b633e1c5-b582-4048-a93e-9f11b44c7e96` | Send mail as any user |
| Application.Read.All | `9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30` | Read all applications |

For a complete list, see [Microsoft Graph permissions reference](https://learn.microsoft.com/en-us/graph/permissions-reference).

## Admin Consent

### Delegated Permissions

Delegated permissions can be granted automatically via the module:

```hcl
enable_admin_consent                 = true
admin_consent_scope                  = ["User.Read", "Mail.Read"]
resource_service_principal_object_id = data.azuread_service_principal.microsoft_graph.object_id
```

### Application Permissions

Application permissions require admin consent via the Azure Portal or PowerShell:

**Via Azure Portal:**
1. Navigate to Azure Portal > Entra ID > App registrations
2. Select your application
3. Go to API permissions
4. Click "Grant admin consent for [your tenant]"

**Via PowerShell:**
```powershell
Connect-MgGraph -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All"

# Get the service principal
$sp = Get-MgServicePrincipal -Filter "displayName eq 'Your App Name'"

# Grant admin consent for application permissions
# (This requires the specific app role assignment creation)
```

## Outputs

After applying, Terraform will output important application details:

```bash
# View all outputs
terraform output

# View specific outputs in JSON format
terraform output -json | jq '.web_api_example_application_id.value'
```

Common outputs:
- `application_id`: Application (client) ID for authentication
- `client_id`: Client ID (same as application_id)
- `service_principal_id`: Service principal object ID
- `service_principal_object_id`: Service principal object ID for role assignments
- `oauth2_permission_scope_ids`: Map of OAuth2 permission scope values to IDs
- `app_role_ids`: Map of app role values to IDs

**Note:** Client secrets and certificates are NOT included in outputs as they are not managed by Terraform. Create and manage credentials separately via Azure Portal or CLI.

## Security Best Practices

1. **Use Workload Identity Federation**: Eliminate secrets entirely by using federated credentials for GitHub Actions, Kubernetes, and other supported platforms
2. **Use Managed Identities**: Where possible, use Azure Managed Identities instead of service principals for Azure-to-Azure authentication
3. **Secrets Outside Terraform**: Never manage client secrets or certificates in Terraform - use Azure Key Vault with RBAC
4. **Least Privilege**: Only request the minimum required API permissions for your application
5. **Separate Environments**: Use separate app registrations for dev/test/prod with appropriate lifecycle protections
6. **Lifecycle Protection**: Set `prevent_destroy = true` for production applications to prevent accidental deletion
7. **Monitoring**: Enable sign-in logs and monitor for suspicious activity using Azure AD logs
8. **Conditional Access**: Apply conditional access policies to service principals to enforce security requirements
9. **Regular Reviews**: Periodically review API permissions and remove unused applications
10. **Audit Trail**: All credential operations should be performed manually to maintain proper audit trails

## Troubleshooting

### Permission Errors

If you encounter permission errors:

```
Error: Insufficient privileges to complete the operation
```

Ensure your account has the required Entra ID role:
- Application Administrator
- Cloud Application Administrator
- Global Administrator

### Admin Consent Issues

If admin consent fails for application permissions, grant consent manually via the portal or use PowerShell with appropriate permissions.

### Federated Credential Errors

For GitHub Actions federated credentials:
- Verify the `issuer` URL is correct: `https://token.actions.githubusercontent.com`
- Ensure the `subject` matches your repository and branch/environment
- Check that the audience is: `["api://AzureADTokenExchange"]`

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly in a non-production environment
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## References

- [Microsoft Entra ID Documentation](https://learn.microsoft.com/en-us/entra/identity/)
- [Terraform AzureAD Provider](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs)
- [Microsoft Graph Permissions Reference](https://learn.microsoft.com/en-us/graph/permissions-reference)
- [Workload Identity Federation](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation)
- [Application Registration Best Practices](https://learn.microsoft.com/en-us/entra/identity-platform/security-best-practices-for-app-registration)

## Support

For issues, questions, or contributions, please open an issue in this repository.

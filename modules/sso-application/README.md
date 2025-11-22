# SSO Application Module

This Terraform module creates and manages Microsoft Entra ID (Azure AD) application registrations with service principals, including comprehensive support for API permissions, authentication methods, and admin consent.

## Features

- Application registration with customizable properties
- Service principal creation and management
- Multiple authentication methods:
  - Client secrets with automatic rotation
  - Certificate-based authentication
  - Federated identity credentials (workload identity)
- API permissions management
- Admin consent automation for delegated permissions
- App roles and OAuth2 permission scopes
- SAML SSO configuration
- Optional claims configuration
- Group membership claims

## Usage

### Basic Web Application

```hcl
module "web_app" {
  source = "./modules/sso-application"

  display_name = "My Web Application"

  web_redirect_uris = [
    "https://myapp.example.com/auth/callback"
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
}
```

### SPA with PKCE

```hcl
module "spa" {
  source = "./modules/sso-application"

  display_name = "My SPA"

  spa_redirect_uris = [
    "http://localhost:3000",
    "https://myapp.example.com"
  ]

  create_client_secret = false

  required_resource_access = [
    {
      resource_app_id = "00000003-0000-0000-c000-000000000000"
      resource_access = [
        {
          id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
          type = "Scope"
        }
      ]
    }
  ]
}
```

### Background Service with Application Permissions

```hcl
module "service" {
  source = "./modules/sso-application"

  display_name = "Background Service"

  required_resource_access = [
    {
      resource_app_id = "00000003-0000-0000-c000-000000000000"
      resource_access = [
        {
          id   = "df021288-bdef-4463-88db-98f22de89214" # User.Read.All
          type = "Role"
        }
      ]
    }
  ]

  create_client_secret   = true
  password_rotation_days = 180
}
```

### Workload Identity (GitHub Actions)

```hcl
module "github_workload" {
  source = "./modules/sso-application"

  display_name = "GitHub Actions"

  create_client_secret = false

  federated_identity_credentials = [
    {
      display_name = "GitHub Main Branch"
      description  = "GitHub Actions main branch"
      audiences    = ["api://AzureADTokenExchange"]
      issuer       = "https://token.actions.githubusercontent.com"
      subject      = "repo:org/repo:ref:refs/heads/main"
    }
  ]
}
```

## Inputs

### Required Inputs

| Name | Type | Description |
|------|------|-------------|
| `display_name` | string | The display name for the application |

### Optional Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `description` | string | null | Application description |
| `sign_in_audience` | string | "AzureADMyOrg" | Microsoft account types supported |
| `app_owners` | list(string) | [] | List of user object IDs who will own the application |
| `identifier_uris` | list(string) | null | Application ID URIs |
| `web_redirect_uris` | list(string) | null | Redirect URIs for web applications |
| `spa_redirect_uris` | list(string) | null | Redirect URIs for SPAs |
| `public_client_redirect_uris` | list(string) | null | Redirect URIs for public clients |
| `required_resource_access` | list(object) | null | API permissions required by the application |
| `create_client_secret` | bool | true | Whether to create a client secret |
| `password_rotation_days` | number | 180 | Days before secret expiration |
| `certificate_value` | string | null | Certificate value (PEM format) |
| `federated_identity_credentials` | list(object) | null | Federated identity credentials |
| `enable_admin_consent` | bool | false | Grant admin consent for delegated permissions |
| `app_role_assignment_required` | bool | false | Require user assignment to service principal |
| `preferred_single_sign_on_mode` | string | null | SSO mode (saml, password, oidc, notSupported) |

See [variables.tf](./variables.tf) for complete list of inputs.

## Outputs

| Name | Description |
|------|-------------|
| `application_id` | Application (client) ID |
| `application_object_id` | Application object ID |
| `service_principal_id` | Service principal object ID |
| `client_secret` | Client secret value (sensitive) |
| `certificate_thumbprint` | Certificate thumbprint |
| `oauth2_permission_scope_ids` | Map of OAuth2 scope names to IDs |
| `app_role_ids` | Map of app role values to IDs |

See [outputs.tf](./outputs.tf) for complete list of outputs.

## Authentication Methods

### Client Secret (Default)

```hcl
create_client_secret   = true
password_rotation_days = 180
```

### Certificate

```hcl
certificate_value = file("path/to/cert.pem")
certificate_type  = "AsymmetricX509Cert"
```

### Federated Identity (Passwordless)

```hcl
create_client_secret = false

federated_identity_credentials = [
  {
    display_name = "GitHub Actions"
    audiences    = ["api://AzureADTokenExchange"]
    issuer       = "https://token.actions.githubusercontent.com"
    subject      = "repo:org/repo:ref:refs/heads/main"
  }
]
```

## API Permissions

API permissions are configured using the `required_resource_access` variable:

```hcl
required_resource_access = [
  {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
    resource_access = [
      {
        id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # Permission ID
        type = "Scope" # or "Role" for application permissions
      }
    ]
  }
]
```

## Admin Consent

Delegated permissions can be consented automatically:

```hcl
enable_admin_consent                 = true
admin_consent_scope                  = ["User.Read", "Mail.Read"]
resource_service_principal_object_id = "microsoft-graph-sp-object-id"
```

**Note**: Application permissions require manual consent via Portal or PowerShell.

## License

MIT

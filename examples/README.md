# Application Pattern Examples

This directory contains complete examples for each authentication pattern supported by the `sso-application` module.

## 📋 Quick Reference

Aligned with [Microsoft Entra ID application types](https://learn.microsoft.com/en-us/entra/identity-platform/v2-app-types)

| Pattern | Microsoft Term | Use Case | Example File | Auth Flow |
|---------|----------------|----------|--------------|-----------|
| **web_app** | Web apps | Traditional web apps (server-side) | [web-app.tf](./web-app.tf) | Authorization Code + PKCE |
| **spa** | Single-page apps | JavaScript apps (React, Vue, Angular) | [spa-app.tf](./spa-app.tf) | Authorization Code + PKCE |
| **mobile** | Mobile and desktop apps | iOS, Android, native apps | [mobile-app.tf](./mobile-app.tf) | Authorization Code + PKCE |
| **service** | Services and daemons | Background services, APIs | [service-app.tf](./service-app.tf) | Client Credentials |
| **saml** | SAML apps | Enterprise SSO, legacy integration | [saml-app.tf](./saml-app.tf) | SAML 2.0 |
| **multitenant** | Multi-tenant apps | SaaS platforms, ISV apps | [multitenant-app.tf](./multitenant-app.tf) | Authorization Code + PKCE |

---

## 🎯 **Permission Helpers** - No More GUIDs!

Instead of looking up permission GUIDs, use friendly names:

```hcl
# ✅ NEW WAY - Permission helpers (easy!)
graph_delegated_permissions = [
  "User.Read",
  "Mail.Send",
  "Calendars.Read"
]

graph_application_permissions = [
  "User.Read.All",
  "Directory.Read.All"
]

# ❌ OLD WAY - Manual GUIDs (tedious)
required_resource_access = [{
  resource_app_id = "00000003-0000-0000-c000-000000000000"
  resource_access = [
    { id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d", type = "Scope" }  # User.Read
  ]
}]
```

**Key points:**
- `graph_delegated_permissions`: Delegated (on behalf of user) - type = "Scope"
- `graph_application_permissions`: Application (app acts as itself) - type = "Role"
- Both can be used together
- Still works with manual `required_resource_access` for non-Graph APIs
- See [Microsoft Graph permissions reference](https://learn.microsoft.com/en-us/graph/permissions-reference) for all available permissions

---

## 🤖 Daemon / Service Applications

**When to use:**
- Background services with no user interaction
- API-to-API communication
- Scheduled jobs and automation
- CI/CD pipelines

**Key characteristics:**
- ✅ No redirect URIs (no user login)
- ✅ Application permissions (acts as itself)
- ✅ Client credentials or federated identity
- ❌ No user context

**Example:**
```hcl
module "api_service" {
  source = "../modules/sso-application"

  app_pattern  = "service"
  display_name = "Backend API Service"

  # No redirect URIs

  # Use permission helpers!
  graph_application_permissions = [
    "User.Read.All",
    "Directory.Read.All"
  ]

  # Prefer federated identity over secrets
  federated_identity_credentials = [...]
}
```

**Security notes:**
- Prefer Workload Identity Federation (no secrets!)
- If using secrets, rotate frequently (90 days max)
- Grant least-privilege permissions
- Monitor API usage for anomalies

**See:** [service-app.tf](./service-app.tf) for complete example

---

## 🌐 Web Applications (OIDC)

**When to use:**
- Server-rendered web applications
- Traditional MVC apps
- Any app with server-side code

**Key characteristics:**
- ✅ Redirect URIs for callback
- ✅ PKCE enforced (security)
- ✅ Can securely store client secret
- ✅ Delegated permissions (on behalf of user)

**Example:**
```hcl
module "employee_portal" {
  source = "../modules/sso-application"

  app_pattern  = "web_app"
  display_name = "Employee Portal"

  web_redirect_uris = [
    "https://portal.example.com/signin-oidc"
  ]

  # Use permission helpers!
  graph_delegated_permissions = [
    "User.Read",
    "Mail.Send"
  ]

  create_client_secret = true
}
```

**Supported frameworks:**
- ASP.NET Core
- Node.js / Express
- Python / Django / Flask
- Ruby on Rails
- PHP / Laravel

**See:** [web-app.tf](./web-app.tf) for complete example

---

## ⚡ Single Page Applications (SPA)

**When to use:**
- React, Vue, Angular apps
- Progressive Web Apps (PWAs)
- Client-side JavaScript apps

**Key characteristics:**
- ✅ SPA redirect URIs
- ✅ PKCE enforced (mandatory for SPAs)
- ✅ Public client (no client secret)
- ❌ Cannot securely store secrets

**Example:**
```hcl
module "dashboard_spa" {
  source = "../modules/sso-application"

  app_pattern  = "spa"
  display_name = "Analytics Dashboard"

  spa_redirect_uris = [
    "https://dashboard.example.com/callback",
    "http://localhost:3000" # Dev
  ]

  create_client_secret = false # SPAs are public clients
}
```

**Important:**
- Use MSAL.js library (@azure/msal-browser)
- Tokens stored in browser (sessionStorage recommended)
- Consider Backend-for-Frontend (BFF) pattern for sensitive operations
- Never call APIs with client secrets from browser

**See:** [spa-app.tf](./spa-app.tf) for complete example

---

## 🔐 SAML Applications

**When to use:**
- Enterprise SaaS integration (Salesforce, ServiceNow, etc.)
- Legacy applications requiring SAML
- Federation with external identity providers

**Key characteristics:**
- ✅ XML-based SAML 2.0 protocol
- ✅ Typically requires user assignment
- ✅ Certificate-based signing
- ✅ Works with non-Microsoft apps

**Example:**
```hcl
module "salesforce_sso" {
  source = "../modules/sso-application"

  app_pattern  = "saml"
  display_name = "Salesforce SSO"

  identifier_uris = ["https://example.my.salesforce.com"]

  web_redirect_uris = [
    "https://example.my.salesforce.com/services/auth/saml/SSO"
  ]

  notification_email_addresses = ["identity-team@example.com"]
}
```

**Certificate management:**
- Certificates are NOT managed by Terraform
- Azure AD auto-generates certificates (3-year validity)
- Renew certificates before expiration
- Configure notification emails for alerts

**See:** [saml-app.tf](./saml-app.tf) for complete example

---

## 🔒 Security Best Practices by Pattern

### All Patterns
- ✅ Enable `prevent_destroy = true` for production
- ✅ Use least-privilege permissions
- ✅ Monitor sign-ins and API usage
- ✅ Keep dependencies updated

### Daemon Apps
- ✅ **Prefer:** Workload Identity Federation (no secrets)
- ⚠️ **If secrets needed:** Rotate every 90 days or less
- ✅ Use managed identities when possible
- ✅ Store secrets in Azure Key Vault

### Web Apps
- ✅ PKCE is enforced (implicit grant disabled)
- ✅ Store client secrets in Key Vault
- ✅ Validate tokens on backend
- ✅ Use HTTPS everywhere

### SPAs
- ✅ PKCE is mandatory
- ✅ No client secrets (public client)
- ✅ Use sessionStorage over localStorage
- ✅ Implement token refresh properly
- ⚠️ Consider BFF pattern for sensitive data

### SAML Apps
- ✅ Require user assignment
- ✅ Monitor certificate expiration
- ✅ Test certificate renewal process
- ✅ Document SP configuration

---

## 🚀 Getting Started

1. **Choose your pattern** based on the table above
2. **Copy the example file** for your pattern
3. **Customize** the configuration for your app
4. **Review** security settings and permissions
5. **Test** in dev/test environment first
6. **Deploy** to production with `prevent_destroy = true`

---

## 📚 Additional Resources

- [Microsoft Identity Platform Documentation](https://learn.microsoft.com/en-us/azure/active-directory/develop/)
- [OAuth 2.0 and OIDC Overview](https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-protocols)
- [SAML Protocol Reference](https://learn.microsoft.com/en-us/azure/active-directory/develop/saml-protocol-reference)
- [Microsoft Authentication Libraries (MSAL)](https://learn.microsoft.com/en-us/azure/active-directory/develop/msal-overview)
- [Workload Identity Federation](https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation)

---

## ❓ Which Pattern Should I Use?

### Decision Tree

```
Who will use this application?
├─ Multiple Azure AD organizations → multitenant
│
├─ No user (service/automation) → service (Client Credentials)
│
└─ Users from my organization → What kind of application?
    ├─ Server-side web app (ASP.NET, Node.js, Django) → web_app
    ├─ Client-side SPA (React, Vue, Angular) → spa
    ├─ Mobile or desktop app (iOS, Android, Electron) → mobile
    ├─ Enterprise SSO (Salesforce, ServiceNow) → saml
    └─ Legacy SAML integration → saml
```

### Still not sure?

| If you're building... | Use this pattern |
|----------------------|------------------|
| Multi-tenant SaaS platform | **multitenant** |
| iOS/Android mobile app | **mobile** |
| Electron desktop app | **mobile** |
| React/Vue/Angular dashboard | **spa** |
| ASP.NET Core web app | **web_app** |
| Background data sync job | **service** |
| Integration with Salesforce | **saml** |
| REST API (no UI) | **service** |
| Node.js/Django/Flask web app | **web_app** |
| Progressive Web App (PWA) | **spa** |
| GitHub Actions workflow | **service** (with federated identity) |
| .NET MAUI app | **mobile** |
| App sold in Azure Marketplace | **multitenant** |

---

## 🛠️ Troubleshooting

### "Invalid redirect URI"
- Check that your redirect URI exactly matches your app's configuration
- For SPAs, use `spa_redirect_uris` (not `web_redirect_uris`)
- Include protocol (https://) and no trailing slash

### "AADSTS50011: The reply URL does not match"
- Verify redirect URI in both Terraform and your application code
- Check for http vs https mismatch
- Ensure you're using the correct redirect URI for the environment

### "AADSTS65001: The user or administrator has not consented"
- Admin consent required for application permissions (service apps)
- Use `azuread_app_role_assignment` resource
- Or grant consent via Azure Portal

### "AADSTS7000218: The request body must contain client_assertion"
- Your app is configured for certificate/federated identity but sending client secret
- Either remove federated_identity_credentials or use the configured credential type

---

## 💬 Need Help?

- Check the [main README](../README.md) for module documentation
- Review [CONTRIBUTING.md](../CONTRIBUTING.md) for development guidelines
- Open an issue for bugs or feature requests

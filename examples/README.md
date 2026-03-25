# Application Pattern Examples

This directory contains complete examples for each authentication pattern supported by the `sso-application` module.

## 📋 Quick Reference

| Pattern | Use Case | Example File | Auth Flow |
|---------|----------|--------------|-----------|
| **daemon** | Background services, APIs, batch jobs | [daemon-app.tf](./daemon-app.tf) | Client Credentials |
| **oidc_web** | Traditional web apps (server-side) | [web-app.tf](./web-app.tf) | Authorization Code + PKCE |
| **oidc_spa** | Single-page apps (React, Vue, Angular) | [spa-app.tf](./spa-app.tf) | Authorization Code + PKCE |
| **saml** | Enterprise SSO, SaaS integration | [saml-app.tf](./saml-app.tf) | SAML 2.0 |

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

  app_pattern  = "daemon"
  display_name = "Backend API Service"

  # No redirect URIs

  required_resource_access = [{
    resource_app_id = local.microsoft_graph_app_id
    resource_access = [{
      id   = "df021288-bdef-4463-88db-98f22de89214" # User.Read.All
      type = "Role" # Application permission
    }]
  }]

  # Prefer federated identity over secrets
  federated_identity_credentials = [...]
}
```

**Security notes:**
- Prefer Workload Identity Federation (no secrets!)
- If using secrets, rotate frequently (90 days max)
- Grant least-privilege permissions
- Monitor API usage for anomalies

**See:** [daemon-app.tf](./daemon-app.tf) for complete example

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

  app_pattern  = "oidc_web"
  display_name = "Employee Portal"

  web_redirect_uris = [
    "https://portal.example.com/signin-oidc"
  ]

  required_resource_access = [{
    resource_app_id = local.microsoft_graph_app_id
    resource_access = [{
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope" # Delegated permission
    }]
  }]

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

  app_pattern  = "oidc_spa"
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
Is there a user logging in?
├─ NO → daemon (Client Credentials)
│
└─ YES → What kind of application?
    ├─ Server-side web app → oidc_web
    ├─ Client-side SPA (React/Vue/Angular) → oidc_spa
    └─ Enterprise SaaS or legacy → saml
```

### Still not sure?

| If you're building... | Use this pattern |
|----------------------|------------------|
| A React dashboard | **oidc_spa** |
| An ASP.NET Core web app | **oidc_web** |
| A background data sync job | **daemon** |
| Integration with Salesforce | **saml** |
| A REST API (no UI) | **daemon** |
| A Node.js web app | **oidc_web** |
| A Vue.js PWA | **oidc_spa** |
| GitHub Actions workflow | **daemon** (with federated identity) |

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
- Admin consent required for application permissions (daemon apps)
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

# Example: Mobile and Desktop Application
#
# Microsoft terminology: "Mobile and desktop apps" (public client)
# https://learn.microsoft.com/en-us/entra/identity-platform/v2-app-types#mobile-and-desktop-apps
#
# Use case: Native mobile apps (iOS, Android) and desktop applications
# Auth flow: Authorization Code + PKCE (OAuth 2.0 / OpenID Connect)
# No client secret (public client - can't securely store secrets)
#
# Examples:
# - iOS apps (Swift/Objective-C)
# - Android apps (Kotlin/Java)
# - .NET MAUI applications
# - Electron desktop apps
# - Windows WPF/UWP apps

module "mobile_app" {
  source = "../modules/sso-application"

  # Pattern auto-applies security defaults for mobile apps:
  # - Enforces PKCE (mobile apps are public clients)
  # - Disables implicit grant flow
  # - No client secret (can't be secured in mobile apps)
  app_pattern  = "mobile"
  display_name = "Acme Mobile App"
  description  = "iOS and Android mobile application"

  # Public client redirect URIs (custom URL schemes or web redirects)
  public_client_redirect_uris = [
    # iOS - Custom URL scheme
    "msauth.com.acme.mobileapp://auth",

    # Android - Custom URL scheme
    "msauth://com.acme.mobileapp/callback",

    # Universal/App Links (iOS) - RECOMMENDED
    "https://app.acme.com/auth/callback",

    # Android App Links - RECOMMENDED
    "https://app.acme.com/.well-known/assetlinks.json",

    # Local development/testing
    "http://localhost",
    "http://localhost:8080",

    # MSAL broker redirect (for iOS/Android with Microsoft Authenticator)
    "msauth.com.acme.mobileapp://auth",
  ]

  # Delegated permissions (user consent)
  graph_delegated_permissions = [
    "User.Read",
    "openid",
    "email",
    "profile"
  ]

  # Optional claims for mobile apps
  optional_claims = {
    id_token = [
      { name = "email", essential = true, source = null, additional_properties = null }
    ]
    access_token = [
      { name = "upn", essential = false, source = null, additional_properties = null }
    ]
    saml2_token = null
  }

  # Mobile apps don't use client secrets (public clients)
  create_client_secret = false

  tags = local.common_tag_list
  notes = "Mobile application for iOS and Android"
}

# ═══════════════════════════════════════════════════════════════════════════
# MOBILE APP BEST PRACTICES
# ═══════════════════════════════════════════════════════════════════════════
#
# 1. USE BROKER AUTHENTICATION (RECOMMENDED)
#    - iOS: Microsoft Authenticator or Company Portal
#    - Android: Microsoft Authenticator or Company Portal
#    - Benefits: SSO, conditional access, device compliance
#    - See: https://learn.microsoft.com/en-us/entra/msal/dotnet/acquiring-tokens/desktop-mobile/wam
#
# 2. REDIRECT URI SCHEMES
#    ✅ RECOMMENDED: HTTPS App Links / Universal Links
#       - iOS: https://app.acme.com/auth/callback
#       - Android: https://app.acme.com/auth/callback
#       - More secure than custom URL schemes
#       - No scheme hijacking
#
#    ⚠️  ACCEPTABLE: Custom URL schemes
#       - iOS: msauth.com.acme.mobileapp://auth
#       - Android: msauth://com.acme.mobileapp/callback
#       - Risk: Other apps can register same scheme
#
# 3. PKCE IS MANDATORY
#    - Enforced automatically by app_pattern = "mobile"
#    - Protects against authorization code interception
#    - Required by OAuth 2.0 for native apps (RFC 8252)
#
# 4. NO CLIENT SECRETS
#    - Mobile apps are public clients
#    - Cannot securely store secrets (reverse engineering risk)
#    - Use PKCE instead
#
# 5. TOKEN STORAGE
#    - iOS: Keychain Services
#    - Android: EncryptedSharedPreferences or Keystore
#    - Never use UserDefaults/SharedPreferences (unencrypted)
#
# 6. OFFLINE ACCESS
#    - Use refresh tokens for offline access
#    - Store securely in platform keychain
#    - Handle token expiration gracefully
#
# ═══════════════════════════════════════════════════════════════════════════

# Outputs for mobile app configuration
output "mobile_app_config" {
  description = "Configuration for iOS and Android apps"
  value = {
    tenant_id     = local.tenant_id
    client_id     = module.mobile_app.application_id
    authority     = "https://login.microsoftonline.com/${local.tenant_id}"
    redirect_uri  = "msauth.com.acme.mobileapp://auth"
    scopes        = ["User.Read", "openid", "profile", "email"]
  }
}

# iOS configuration example (Info.plist)
output "ios_config_example" {
  description = "iOS Info.plist configuration snippet"
  value = <<-EOT
    <!-- Info.plist -->
    <key>CFBundleURLTypes</key>
    <array>
      <dict>
        <key>CFBundleURLSchemes</key>
        <array>
          <string>msauth.com.acme.mobileapp</string>
        </array>
      </dict>
    </array>

    <!-- MSAL Configuration -->
    <key>MSALClientID</key>
    <string>${module.mobile_app.application_id}</string>
    <key>MSALRedirectUri</key>
    <string>msauth.com.acme.mobileapp://auth</string>
  EOT
}

# Android configuration example (AndroidManifest.xml)
output "android_config_example" {
  description = "Android AndroidManifest.xml configuration snippet"
  value = <<-EOT
    <!-- AndroidManifest.xml -->
    <activity
        android:name="com.microsoft.identity.client.BrowserTabActivity">
        <intent-filter>
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.DEFAULT" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data
                android:scheme="msauth"
                android:host="com.acme.mobileapp"
                android:path="/callback" />
        </intent-filter>
    </activity>

    <!-- MSAL auth_config.json -->
    {
      "client_id": "${module.mobile_app.application_id}",
      "authorization_user_agent": "DEFAULT",
      "redirect_uri": "msauth://com.acme.mobileapp/callback",
      "broker_redirect_uri_registered": true,
      "authorities": [
        {
          "type": "AAD",
          "audience": {
            "type": "AzureADMyOrg",
            "tenant_id": "${local.tenant_id}"
          }
        }
      ]
    }
  EOT
}

# MSAL code example
output "msal_code_example" {
  description = "MSAL authentication code example"
  value = <<-EOT
    # iOS (Swift) with MSAL
    import MSAL

    let config = MSALPublicClientApplicationConfig(
        clientId: "${module.mobile_app.application_id}",
        redirectUri: "msauth.com.acme.mobileapp://auth",
        authority: try MSALAuthority(url: URL(string: "https://login.microsoftonline.com/${local.tenant_id}")!)
    )

    let application = try MSALPublicClientApplication(configuration: config)

    // Android (Kotlin) with MSAL
    val app = PublicClientApplication.create(
        context,
        R.raw.auth_config
    )

    val parameters = AcquireTokenParameters.Builder()
        .startAuthorizationFromActivity(activity)
        .withScopes(listOf("User.Read", "openid", "profile"))
        .withCallback(getAuthCallback())
        .build()

    app.acquireToken(parameters)
  EOT
}

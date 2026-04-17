# SSO and Identity: Glossary

**Purpose:** Define acronyms and concepts so you can read the [SSO feature matrix](sso-feature-matrix.md) and docs with confidence.  
**See also:** [sso-feature-matrix.md](sso-feature-matrix.md) (comparison table), [sso-features-explained.md](sso-features-explained.md) (feature-by-feature purpose and per-product detail).

---

## Core concepts

**SSO (Single Sign-On)**  
- **What it is:** One login grants access to multiple apps (e.g. Jellyfin, Calibre-Web, *arr UIs) without logging in again.  
- **Why it matters:** Fewer passwords, one place to enforce MFA and revoke access.  
- **In practice:** You sign in once at an IdP or gateway; a session cookie or token is reused for all protected apps.

**IdP (Identity Provider)**  
- **What it is:** The service that answers “who is this user?” and “prove it.” It holds user accounts and performs login (password, passkey, etc.).  
- **Why it matters:** Apps (Jellyfin, Nextcloud, etc.) can delegate “who is logged in?” to the IdP instead of managing their own user list and passwords.  
- **In practice:** Authelia, Authentik, Keycloak, and PocketID are IdPs. oauth2-proxy is *not* an IdP; it asks another IdP (e.g. Google or PocketID) to do the login.

**Forward auth**  
- **What it is:** A reverse-proxy pattern: before the proxy sends a request to your app, it asks a separate “auth gateway” “is this user allowed?” If not, the user is redirected to login; if yes, the request proceeds (often with a header like `Remote-User`).  
- **Why it matters:** You can protect many apps with one auth layer without each app supporting SSO natively.  
- **In practice:** Caddy’s `forward_auth` directive calls Authelia (or similar); Nginx uses `auth_request`; Traefik has forward auth middleware.

---

## Protocols (how apps and IdPs talk)

**OIDC (OpenID Connect)**  
- **What it is:** A modern standard for “Sign in with X.” Built on OAuth 2.0; adds identity (who the user is) and standard endpoints (login, token, userinfo).  
- **Why it matters:** Most self-hosted apps (Jellyfin SSO plugin, Nextcloud, etc.) support “Sign in with OIDC.” If your IdP speaks OIDC, those apps can use it.  
- **In practice:** Authelia, Authentik, Keycloak, and PocketID all *provide* OIDC. oauth2-proxy and Vouch *consume* OIDC (they talk to Google, GitHub, or your own IdP).

**OAuth 2.0**  
- **What it is:** A protocol for *authorization* (“let this app act on my behalf”) and for obtaining tokens. OIDC sits on top of it to add *authentication* (“who am I?”).  
- **Why it matters:** When we say “OIDC,” we usually mean “OAuth 2.0 + OIDC identity.” IdPs that support OIDC support OAuth 2.0 flows.  
- **In practice:** You rarely configure “OAuth 2.0” alone; you configure “OIDC” (client ID, secret, issuer URL, scopes).

**SAML (Security Assertion Markup Language)**  
- **What it is:** An older, XML-based SSO protocol. Common in enterprises and with legacy apps (e.g. some VPNs, university systems).  
- **Why it matters:** If an app only supports SAML and not OIDC, you need an IdP that supports SAML (Authentik, Keycloak). Homelab apps mostly use OIDC.  
- **In practice:** Authelia and PocketID do *not* support SAML. Authentik and Keycloak do.

---

## Authentication methods

**MFA (Multi-Factor Authentication)**  
- **What it is:** Proving identity with more than one factor: something you know (password), something you have (phone, Yubikey), or something you are (biometric).  
- **Why it matters:** Reduces risk if a password is stolen.  
- **In practice:** “2FA” usually means password + second factor (TOTP or passkey).

**TOTP (Time-based One-Time Password)**  
- **What it is:** The six-digit codes from an app (Google Authenticator, Authy) or from a hardware token. The code changes every 30 seconds.  
- **Why it matters:** Common second factor; no extra hardware.  
- **In practice:** IdP shows a QR code; you add it to an app; at login you enter the current code.

**WebAuthn**  
- **What it is:** A browser standard for strong authentication using a security key (e.g. Yubikey) or device-bound key (e.g. Touch ID, Windows Hello).  
- **Why it matters:** Phishing-resistant; private key never leaves the device.  
- **In practice:** When you “register a passkey,” you’re using WebAuthn. Many IdPs support “WebAuthn” or “security key” as a second factor or as the only factor.

**Passkey**  
- **What it is:** A passwordless credential built on WebAuthn: a key pair (public key at the server, private key on your device or security key). You “sign in” by proving you have the private key (e.g. fingerprint, PIN).  
- **Why it matters:** No password to steal; good UX on supported devices.  
- **In practice:** PocketID is *passkey-only*. Authelia and others support passkeys as an option alongside password + TOTP.

---

## Directories and provisioning

**LDAP (Lightweight Directory Access Protocol)**  
- **What it is:** A protocol and data model for a *directory* of users and groups (usernames, emails, group membership). It does *not* define how users log in (password vs passkey); it defines *who exists*.  
- **Why it matters:** Many organizations already have LDAP or Active Directory. An IdP can use LDAP as the source of users and groups, then apply its own login method (password, passkey).  
- **In practice:** “Supports LDAP” means the IdP can pull user/group list from your LDAP server. Authelia, Authentik, Keycloak, and PocketID can use LDAP.

**SCIM (System for Cross-domain Identity Management)**  
- **What it is:** A standard for *provisioning*: creating, updating, and deprovisioning user accounts in apps from a central IdP or HR system.  
- **Why it matters:** Useful at scale (“new hire” in one place → account in many apps). Less critical for a small homelab.  
- **In practice:** “Supports SCIM” means the IdP can push user lifecycle to SCIM-enabled apps. Authentik and PocketID support it; Authelia does not.

---

## Quick reference

| Term    | One-line meaning |
|---------|------------------|
| SSO     | One login, many apps. |
| IdP     | Service that holds users and does login. |
| OIDC    | Modern “Sign in with X” protocol; apps and IdPs use it. |
| OAuth 2.0 | Underlying protocol for tokens; OIDC builds on it. |
| SAML    | Older XML SSO protocol; enterprise/legacy. |
| MFA / 2FA | More than one factor (e.g. password + code). |
| TOTP    | Six-digit codes from an app (e.g. Google Authenticator). |
| WebAuthn | Browser standard for security keys / device keys. |
| Passkey | Passwordless login (WebAuthn-based). |
| LDAP    | Directory of users/groups; who exists, not how they log in. |
| SCIM    | Standard for syncing user accounts across systems. |
| Forward auth | Proxy asks “allowed?” before sending request to app. |

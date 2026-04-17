# SSO Feature Matrix: Purpose and Details

**Purpose:** For each feature in the [SSO feature matrix](sso-feature-matrix.md), this doc explains *what it is*, *why it matters*, and *how each product handles it*.  
**See also:** [sso-glossary.md](sso-glossary.md) (acronyms and concepts).

---

## 1. Architecture (IdP vs forward auth)

**What it is:** Whether the product *is* the place that holds users and does login (IdP), or a *gate* that delegates to another service (forward auth).  
**Why it matters:** IdPs (Authentik, Keycloak, PocketID, Authelia when used as OIDC) are the “source of truth” for identity. Forward-auth products (Authelia as bouncer, oauth2-proxy, Vouch) sit in front of apps and either check a session or call an IdP.

| Product | How it works |
|---------|--------------|
| Authelia | Can be **forward auth** (Caddy asks it “allowed?”) or **OIDC IdP** (apps “Sign in with Authelia”). |
| Authentik, Keycloak, PocketID | **Full IdP**: they hold users and perform login; apps connect via OIDC (and SAML for Authentik/Keycloak). |
| oauth2-proxy, Vouch | **Forward auth** only: they delegate to an external IdP (Google, GitHub, or your own IdP). |
| Tailscale | **Mesh VPN**: identity is “on Tailscale”; not an IdP or forward-auth product. |

---

## 2. OIDC (OpenID Connect)

**What it is:** The standard protocol for “Sign in with X” and for apps to get identity tokens from an IdP. See [sso-glossary.md](sso-glossary.md#oidc-openid-connect).  
**Why it matters:** Jellyfin SSO plugin and most modern self-hosted apps use OIDC. Your IdP or gateway must speak OIDC (as provider or consumer).

| Product | How it works |
|---------|--------------|
| Authelia, Authentik, Keycloak, PocketID | **OIDC provider**: they issue tokens; Jellyfin and other apps can “Sign in with [IdP].” |
| oauth2-proxy, Vouch | **OIDC consumer**: they talk to Google/GitHub/your IdP; they don’t issue tokens themselves. |

---

## 3. SAML

**What it is:** Older XML-based SSO protocol; common in enterprises and some legacy apps. See [sso-glossary.md](sso-glossary.md#saml-security-assertion-markup-language).  
**Why it matters:** Only needed if you have an app that *only* supports SAML (e.g. some VPNs, university portals). Most homelab apps use OIDC.

| Product | How it works |
|---------|--------------|
| Authentik, Keycloak | **Support SAML**: can act as SAML IdP. |
| Authelia, PocketID, oauth2-proxy, Vouch | **No SAML**: OIDC-only (or delegate to OIDC). |

---

## 4. Built-in user DB (who exists?)

**What it is:** Whether the product stores its own list of users (and optionally groups) or always relies on an external source (LDAP, Google, etc.).  
**Why it matters:** With a built-in DB you don’t need LDAP or Google to define users; simpler for a small homelab.

| Product | How it works |
|---------|--------------|
| Authelia | **File or LDAP**: users in a config file or in your LDAP server. |
| Authentik, Keycloak | **Built-in DB** (Postgres or Keycloak’s DB); can also use LDAP as source. |
| PocketID | **Built-in** (passkey-based users); can use LDAP for user/group source. |
| oauth2-proxy, Vouch | **No user DB**: they delegate to an IdP; “users” are whoever that IdP says. |

---

## 5. External IdP (Google, GitHub, etc.)

**What it is:** Whether users can log in with a *third-party* identity (e.g. “Sign in with Google”) instead of (or in addition to) a self-hosted user list.  
**Why it matters:** Convenient for “login with Google” homelab; less control and dependency on that provider.

| Product | How it works |
|---------|--------------|
| Authentik, Keycloak | **Broker**: can use Google/GitHub/etc. as an *identity source*; user clicks “Sign in with Google” and lands in your IdP, then in the app. |
| oauth2-proxy, Vouch | **Delegate only**: they *only* use an external IdP; no self-hosted user list. |
| Authelia, PocketID | **No built-in “Sign in with Google”**: users are in Authelia/PocketID (or LDAP). You could put oauth2-proxy in front of Authelia in some setups, but that’s a different pattern. |

---

## 6. Auth model (password vs passkey)

**What it is:** How users prove identity: password (often + TOTP/passkey), or passkey-only (no password).  
**Why it matters:** Passkey-only is strong and simple but has recovery/device-loss tradeoffs; password + 2FA is familiar and flexible. See [sso-feature-matrix.md](sso-feature-matrix.md) and earlier discussion on passkey-only drawbacks.

| Product | How it works |
|---------|--------------|
| Authelia, Authentik, Keycloak | **Password + optional MFA** (TOTP, WebAuthn, passkeys). |
| PocketID | **Passkey-only**: no passwords; Yubikey or device passkey. |
| oauth2-proxy, Vouch | **Whatever the external IdP uses** (e.g. Google = password + optional 2FA). |

---

## 7. MFA (TOTP, WebAuthn, Passkeys)

**What it is:** Second (or only) factor: TOTP codes, security key (WebAuthn), or passkey. See [sso-glossary.md](sso-glossary.md#mfa-totp-webauthn-passkey).  
**Why it matters:** Reduces risk of account takeover; passkeys are phishing-resistant.

| Product | How it works |
|---------|--------------|
| Authelia | **TOTP, WebAuthn, passkeys** (and Duo push). |
| Authentik, Keycloak | **TOTP, WebAuthn, passkeys** (and more). |
| PocketID | **Passkeys only** (no TOTP; passkey is the primary auth). |
| oauth2-proxy, Vouch | **Determined by the IdP** (e.g. Google’s 2FA). |

---

## 8. Reverse proxy integration (Caddy / Nginx Proxy Manager)

**What it is:** How the product works *with your reverse proxy* to protect listen/watch/read (and other subdomains).  
**Why it matters:** The SSO layer must plug in cleanly. **Caddy** uses `forward_auth`; **Nginx Proxy Manager (NPM)** uses nginx `auth_request`. On TrueNAS, Caddy isn’t in the Apps catalog—use **NPM**; Authelia has [official NPM docs](https://www.authelia.com/integration/proxies/nginx-proxy-manager/). See also [truenas-apps-sso-and-updates.md](../truenas/truenas-apps-sso-and-updates.md) §4.

| Product | How it works |
|---------|--------------|
| Authelia | **Caddy:** Native `forward_auth`. **Nginx Proxy Manager:** Official support via nginx `auth_request`; use [Authelia NPM guide](https://www.authelia.com/integration/proxies/nginx-proxy-manager/) and [snippets](https://www.authelia.com/integration/proxies/nginx/#supporting-configuration-snippets). On TrueNAS (no Caddy app), use NPM. |
| Authentik, Keycloak, PocketID | **As OIDC IdP**: Proxy doesn’t talk OIDC directly. You put **caddy-security** (Caddy) or **oauth2-proxy** in front and point it at the IdP; or with NPM you’d use an OIDC-aware middleware if available. |
| oauth2-proxy, Vouch | **forward_auth** / **auth_request**: Proxy forwards to the auth proxy; it talks to Google/IdP and sets a cookie. |

---

## 9. Jellyfin SSO plugin

**What it is:** Jellyfin’s plugin that lets users “Sign in with [OIDC IdP]” so one SSO login maps to the correct Jellyfin user.  
**Why it matters:** Multiple users in the IdP can each land in their own Jellyfin account; no need to share one Jellyfin password.

| Product | How it works |
|---------|--------------|
| Authelia, Authentik, Keycloak, PocketID | **Yes**: configure Jellyfin SSO plugin with the IdP’s OIDC endpoints (issuer, client ID, secret). Each IdP user maps to a Jellyfin user (by username/email). |
| oauth2-proxy, Vouch | **Indirect**: they protect *access* to Jellyfin (you must log in via Google/IdP to reach Jellyfin). Jellyfin itself can still use its own login *or* you can point Jellyfin SSO plugin at the same IdP that oauth2-proxy uses (e.g. Google). So “Via IdP” = Jellyfin talks OIDC to that IdP. |

---

## 10. Dependencies and resources

**What it is:** Extra services (DB, cache) and typical RAM so you can plan where to run the product (e.g. Pi 5 vs a beefier host).  
**Why it matters:** Authelia is light; Authentik/Keycloak need Postgres (and Redis for Authentik); PocketID is lighter; oauth2-proxy/Vouch are minimal.

| Product | Typical deps and RAM |
|---------|----------------------|
| Authelia | None (or LDAP). ~20–30 MB RAM idle (file + Argon2 can spike; SHA512 or LDAP avoids that). |
| Authentik | PostgreSQL, Redis. 512 MB+ RAM. |
| Keycloak | DB (built-in or external). 400+ MB RAM. |
| PocketID | Minimal (Docker); no published RAM spec; lighter than Keycloak/Authentik. |
| oauth2-proxy, Vouch | None. &lt;50 MB RAM. |

---

## Index

- [sso-glossary.md](sso-glossary.md) — Acronyms and concepts  
- [sso-feature-matrix.md](sso-feature-matrix.md) — Compact comparison table  
- [servarr-pi5-architecture.md](servarr-pi5-architecture.md) — §6 SSO options for xcvr.link

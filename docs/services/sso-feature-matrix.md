# SSO for Exposed Subdomains: Feature Matrix

**Context:** Protecting listen/watch/read (and other xcvr.link subdomains) with a single sign-on layer.  
**Proxy:** Caddy with `forward_auth`.  
**Full architecture:** `servarr-pi5-architecture.md` §6.

**Need to understand the terms?** See **[sso-glossary.md](sso-glossary.md)** (acronyms and concepts) and **[sso-features-explained.md](sso-features-explained.md)** (purpose and details for each feature, per product).

---

## What self-hosters typically do

- **Homelab / low-resource (e.g. Pi 5):** **Authelia** + reverse proxy `forward_auth`. One login at e.g. `sso.xcvr.link`; session cookie covers all protected subdomains. Lightweight (~20–30 MB RAM idle), YAML config, 2FA (TOTP, WebAuthn, Passkeys). No SAML.
- **SMB / teams / “proper IdP”:** **Authentik**. Full OIDC/OAuth2/SAML IdP, visual flow editor, PostgreSQL + Redis. ~512 MB+ RAM. Jellyfin and many apps have SSO plugins that talk OIDC to Authentik.
- **Enterprise / SAML / AD:** **Keycloak**. Full IdP (Red Hat), steep learning curve, 400+ MB RAM. Overkill for most homelabs.
- **“Login with Google” only:** **oauth2-proxy** or **Vouch**. No self-hosted user DB; they delegate to Google/GitHub/any OIDC. Caddy `forward_auth` → proxy; cookie grants access. Minimal infra, less control.
- **No public login:** **Tailscale**. Don’t expose services; reach them over Tailscale. Identity = Tailscale; not SSO for public subdomains.
- **Passkey-only OIDC:** **PocketID**. Simple OIDC IdP, passkey-only (no passwords). Lighter than Keycloak/Authentik; use with **caddy-security** or **oauth2-proxy** (PocketID as OIDC provider) in front of Caddy. LDAP/SCIM supported. Good fit if you want Yubikey/passkey-only and minimal IdP surface.

Other options (Zitadel, Casdoor) exist but are less common in homelab-forward_auth setups; Casdoor is Go-based and relatively lightweight with OIDC/SAML.

---

## Feature matrix

| Feature | Authelia | Authentik | Keycloak | PocketID | oauth2-proxy | Vouch | Tailscale |
|--------|----------|-----------|----------|----------|--------------|-------|-----------|
| **Architecture** | Forward auth | Full IdP | Full IdP | Full IdP (OIDC) | Forward auth | Forward auth | Mesh VPN |
| **OAuth 2.0 / OIDC** | ✓ | ✓ | ✓ | ✓ (provider) | ✓ (delegate) | ✓ (delegate) | N/A |
| **SAML** | ✗ | ✓ | ✓ | ✗ | ✗ | ✗ | N/A |
| **Built-in user DB** | ✓ (file/LDAP) | ✓ | ✓ | ✓ (passkeys) | ✗ | ✗ | ✗ |
| **External IdP (Google/GitHub)** | ✗ | ✓ (broker) | ✓ | ✗ | ✓ | ✓ | N/A |
| **Auth model** | Password + 2FA | Password + MFA | Password + MFA | **Passkey-only** | Via IdP | Via IdP | N/A |
| **MFA (TOTP / WebAuthn / Passkeys)** | ✓ | ✓ | ✓ | Passkeys only | Via IdP | Via IdP | N/A |
| **Caddy integration** | ✓ Native forward_auth | ✓ (as OIDC) | ✓ (as OIDC) | Via **caddy-security** or **oauth2-proxy**† | ✓ forward_auth | ✓ (auth_request) | N/A |
| **Jellyfin SSO plugin** | ✓ (OIDC) | ✓ (OIDC) | ✓ (OIDC) | ✓ (OIDC) | Via IdP | Via IdP | N/A |
| **Config style** | YAML | Web GUI + flows | Admin console | Web UI + env | Env/file | Config | Tailscale ACLs |
| **RAM (typical)** | ~20–30 MB idle* | 512 MB+ | 400 MB+ | Light (no published spec) | &lt;50 MB | &lt;50 MB | N/A |
| **Dependencies** | None (or LDAP) | PostgreSQL, Redis | DB (built-in or external) | Minimal (Docker) | None | None | Tailnet |
| **Learning curve** | Low | Medium | High | Low | Low | Low | Low |
| **Best for** | Homelab, Pi | SMB, teams | Enterprise, SAML | Passkey-only homelab | “Login with Google” | “Login with Google” | Private access only |

† PocketID is the OIDC provider; you put **caddy-security** (greenpau/caddy-security) or **oauth2-proxy** in front of your apps and point them at PocketID. Native Caddy `forward_auth` does not talk OIDC to PocketID directly. There is a [known bug](https://github.com/pocket-id/pocket-id/issues/312) when Caddy proxies *PocketID itself* (token exchange); using PocketID as IdP with caddy-security/oauth2-proxy in front of *your* services is the documented pattern.

\* Authelia with **file backend + Argon2id** can spike RAM on login (known issue); SHA512 or LDAP avoids that. See [Authelia #5939](https://github.com/authelia/authelia/discussions/5939).

---

## Recommendation for Pi 5 (xcvr.link)

- **Default:** **Authelia** + Caddy `forward_auth` at `sso.xcvr.link`. Protect listen/watch/read (and any other apps) with one session. Use file backend + SHA512 if you want to avoid Argon2 RAM spikes on a memory-tight Pi.
- **If you later need SAML or a full IdP UI:** Consider **Authentik** on a beefier host (or accept higher RAM on Pi 5); Keycloak is usually overkill for homelab.
- **If you only want “Sign in with Google”:** **oauth2-proxy** is the lightest; no user DB to maintain.
- **If you want passkey-only (no passwords):** **PocketID** as OIDC provider + **caddy-security** or **oauth2-proxy** in front of Caddy. One IdP, Yubikey/passkey sign-in everywhere. No SAML.
- **If you don’t want public logins at all:** Use **Tailscale** to reach services; no SSO product needed for those endpoints.

---

## References

- Authelia: [authelia.com](https://www.authelia.com), [Caddy integration](https://www.authelia.com/integration/prologue/get-started/)
- Authentik: [goauthentik.io](https://goauthentik.io)
- Keycloak: [keycloak.org](https://www.keycloak.org)
- oauth2-proxy: [oauth2-proxy.github.io](https://oauth2-proxy.github.io/oauth2-proxy/)
- Vouch: [github.com/vouch/vouch-proxy](https://github.com/vouch/vouch-proxy)
- PocketID: [pocket-id.org](https://pocket-id.org/docs), [Proxy services (Caddy / oauth2-proxy / Traefik)](https://pocket-id.org/docs/guides/proxy-services)
- Community comparisons: Elestio “Authentik vs Authelia vs Keycloak 2026”; House of FOSS “Authelia vs Authentik 2025”

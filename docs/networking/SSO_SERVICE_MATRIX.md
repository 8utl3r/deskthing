# SSO Service Matrix — xcvr.link

**Context:** Hybrid SSO coverage: OIDC where supported, trusted headers where supported, forward_auth/LDAP as fallback. See [SSO_CADDY_AUTHELIA_CHECKLIST.md](SSO_CADDY_AUTHELIA_CHECKLIST.md) for base setup.

---

## Auth method by service

| Service | Auth Method | Notes |
|---------|-------------|-------|
| Immich | OIDC | Configure OAuth in Admin → OAuth; redirect URIs in Authelia |
| Headscale | OIDC | Configure issuer + callback URL in Headscale config |
| Jellyfin | OIDC (SSO plugin) | Install Jellyfin SSO plugin; configure Authelia as OIDC provider |
| Navidrome | Trusted Headers | Set `ND_EXTAUTH_TRUSTEDSOURCES` to Caddy IP (192.168.0.136) |
| Syncthing | LDAP | Configure LDAP server in Syncthing UI (or keep forward_auth) |
| TrueNAS UI | LDAP | Enable Directory Services (or keep forward_auth) |
| n8n | OIDC/LDAP (Enterprise) | Otherwise keep forward_auth gate |
| rules, nas, music, listen, watch, read | forward_auth | No OIDC; Caddy gates access via Authelia |

---

## OIDC clients (Authelia)

OIDC clients are defined in `docs/truenas/authelia-configuration-yml-full-example.yml`. Replace placeholders before deploy:

| Client | Redirect URIs | Secret placeholder |
|--------|--------------|--------------------|
| immich | `https://immich.xcvr.link/auth/login`, `https://immich.xcvr.link/user-settings` | `REPLACE_IMMICH_CLIENT_SECRET` |
| headscale | `https://headscale.xcvr.link/oidc/callback` | `REPLACE_HEADSCALE_CLIENT_SECRET` |
| jellyfin | `https://jellyfin.xcvr.link/sso/OID/redirect/authelia` | `REPLACE_JELLYFIN_CLIENT_SECRET` |

**Generate and deploy:** `./scripts/truenas/authelia-set-oidc-secrets.sh` — generates secrets, prints them for copying into each app, and deploys config.

**Immich mobile:** If using the mobile app, add `app.immich:///oauth-callback` to Immich redirect_uris in Authelia, or use Immich's Mobile Redirect URI Override with an HTTPS alternative.

---

## Implementation order

1. **Authelia:** Deploy config with OIDC clients; replace `REPLACE_*_CLIENT_SECRET` placeholders; restart Authelia.
2. **Per app:** Configure each app for OIDC (Immich Admin → OAuth; Headscale config; Jellyfin SSO plugin).
3. **Verify:** Test OIDC login for each app while forward_auth is still enabled (forward_auth passes; app handles OIDC).
4. **Caddy:** Remove forward_auth for Immich, Headscale, Jellyfin only after OIDC works. Deploy: `./scripts/servarr-pi5-caddy-update.sh`.

**Critical:** Do not remove forward_auth for an app until its OIDC login is verified. Otherwise that app will be unprotected.

---

## Per-service config steps

### Immich

- Admin → OAuth → Enable OAuth
- Issuer URL: `https://sso.xcvr.link`
- Client ID: `immich`
- Client Secret: (same as in Authelia)
- Redirect URIs must match exactly: `/auth/login`, `/user-settings`

### Headscale

- In Headscale config: set OIDC issuer `https://sso.xcvr.link`, client_id `headscale`, client_secret, callback URL `https://headscale.xcvr.link/oidc/callback`

### Jellyfin

- Install Jellyfin SSO plugin (Repository: `https://raw.githubusercontent.com/9p4/jellyfin-plugin-sso/manifest-release/manifest.json`)
- Authentication → SSO Authentication
- OID Endpoint: `https://sso.xcvr.link`
- Name of OID Provider: `authelia`
- OpenID Client ID: `jellyfin`
- OID Secret: (same as in Authelia)
- Request scopes: `openid`, `profile`, `groups`

### Navidrome (trusted headers)

- Set `ND_EXTAUTH_TRUSTEDSOURCES=192.168.0.136` (Caddy/Pi IP)
- Caddy copies `Remote-User`, `Remote-Email`, etc. from forward_auth; Navidrome trusts them from that source

---

## Pitfalls

| Pitfall | Mitigation |
|---------|------------|
| Double-auth loop | Remove forward_auth for OIDC apps. If both forward_auth and app OIDC run, you get redirect loops. |
| Wrong redirect URI | Must match exactly. Jellyfin: `/sso/OID/redirect/authelia` (provider name in path). |
| Header spoofing | Trusted headers only from known proxy IP (ND_EXTAUTH_TRUSTEDSOURCES). |
| Immich mobile | Add `app.immich:///oauth-callback` or use Mobile Redirect URI Override. |

---

## Rollback

If OIDC fails for an app:

1. Re-add forward_auth for that host in the Caddyfile.
2. Deploy Caddy: `./scripts/servarr-pi5-caddy-update.sh`.
3. Users will hit Authelia login first, then the app (which may still show its own login—use forward_auth headers if the app supports them).

To fully revert to forward_auth-only: restore the forward_auth blocks for immich, headscale, jellyfin from git history.

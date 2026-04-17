# xcvr.link — Security Evaluation of Publicly Accessible Services

**Scope:** Every service reachable via Cloudflare Tunnel (public internet).  
**Not publicly tunneled (local-only):** nas, n8n — access on LAN or via VPN/Headscale only.  
**Last evaluated:** 2026-02-22

---

## Summary Table

| Service | Auth | Data sensitivity | Posture | Notes |
|---------|------|------------------|---------|-------|
| sso | Login (Authelia) | High | Strong | SSO portal; no forward_auth (this is the login) |
| headscale | OIDC (app) | High | Strong | Control plane; OIDC at app |
| rules | forward_auth | Medium | Strong | Internal docs |
| immich | OIDC (app) | High | Strong | Photos; OIDC at app |
| syncthing | forward_auth | High | Strong | File sync; gate at Caddy |
| jellyfin | OIDC (app) | Medium | Strong | Media; OIDC at app |
| music | forward_auth | Medium | Strong | Navidrome; gate at Caddy |
| listen / watch / read | forward_auth | Medium | Strong | Jellyfin aliases; gate at Caddy |
| politics | None | Low (by design) | Moderate | Static site; see prod audit below |
| **nas** | — | Critical | **Local only** | TrueNAS UI; do not expose via tunnel |
| **n8n** | — | High | **Local only** | Workflows; do not expose via tunnel |

---

## Per-Service Evaluation

### sso.xcvr.link — Authelia (SSO portal)
- **Auth:** Authelia login (first factor + 2FA if configured). No forward_auth; this is the login page.
- **Data:** Session cookies, identity; high sensitivity.
- **Attack surface:** Login form (credential stuffing, phishing). Ensure 2FA and strong password policy.
- **Posture:** **Strong** — purpose-built IdP; keep Authelia and dependencies updated.

### nas.xcvr.link — TrueNAS UI (local only)
- **Public access:** **No.** Do not add a tunnel route. Use on LAN or via VPN/Headscale only.
- **Auth:** forward_auth when accessed via Caddy on LAN.
- **Data:** Storage config, users, shares, apps; **critical**.

### headscale.xcvr.link — Headscale control server
- **Auth:** OIDC at Headscale (Authelia as IdP). No forward_auth at Caddy.
- **Data:** Tailnet config, ACLs, machine names; high.
- **Attack surface:** Compromise could allow joining your Tailnet. OIDC must be correctly configured.
- **Posture:** **Strong** — verify OIDC callback and issuer in Headscale config.

### rules.xcvr.link — Static rules docs
- **Auth:** forward_auth → Authelia.
- **Data:** Internal documentation; medium.
- **Posture:** **Strong** — gated; content is low-sensitivity.

### immich.xcvr.link — Photos
- **Auth:** OIDC at Immich (Authelia). No forward_auth at Caddy.
- **Data:** Photos, faces, metadata; high.
- **Attack surface:** App-level (SQLi, auth bugs). Rely on Immich + OIDC; keep Immich updated.
- **Posture:** **Strong** — OIDC; ensure redirect URIs and scopes locked down.

### n8n.xcvr.link — Workflows (local only)
- **Public access:** **No.** Do not add a tunnel route. Use on LAN or via VPN/Headscale only.
- **Auth:** forward_auth when accessed via Caddy on LAN.
- **Data:** Workflow defs, credentials in nodes; **high**.

### syncthing.xcvr.link — File sync
- **Auth:** forward_auth → Authelia.
- **Data:** File sync config and (via app) access to synced folders; high.
- **Posture:** **Strong** — gated; Syncthing itself has its own auth layer.

### jellyfin.xcvr.link — Video (Jellyfin)
- **Auth:** OIDC via Jellyfin SSO plugin (Authelia). No forward_auth at Caddy.
- **Data:** Media, watch state; medium.
- **Posture:** **Strong** — OIDC at app; keep Jellyfin and SSO plugin updated.

### music.xcvr.link — Navidrome
- **Auth:** forward_auth → Authelia; trusted headers to Navidrome.
- **Data:** Music library, playlists; medium.
- **Posture:** **Strong** — gated; ND_EXTAUTH_TRUSTEDSOURCES must only include Caddy IP.

### listen.xcvr.link, watch.xcvr.link, read.xcvr.link — Jellyfin aliases
- **Auth:** forward_auth → Authelia, then Jellyfin (same backend as jellyfin.xcvr.link).
- **Posture:** **Strong** — same as jellyfin; extra hostnames are cosmetic.

### politics.xcvr.link — Static site
- **Auth:** None (intentional).
- **Data:** Public political dossiers, analyses, primary sources; low sensitivity by design.
- **Attack surface:** Path traversal (Caddy file_server is safe), XSS if user content is rendered unsafely (yours is static/crafted HTML). No server-side execution.
- **Posture:** **Moderate** — appropriate for public content; risk is sensitive files in prod/ or future injection. See prod audit below.

---

## politics.xcvr.link — prod/ Audit (2026-02-22)

**Scope:** `/Users/pete/politics/prod/` (deployed to NAS webroot).

### Risky patterns checked
- **.env, .env.*, *.key, *.pem, *secret*, *password*, .git*, *.bak, *.backup:** None found.
- **Hidden files/dirs:** No `.env` or `.git` in prod.
- **Config/source in prod:** No `.md`, `.json`, `.yml`, `.yaml` in prod (only HTML).

### Files that matched "secret" in name
- `primary_sources/opensecrets_prop8_search_2026.html`
- `primary_sources/opensecrets_tec_search_2026.html`  
  → Named after OpenSecrets (the org); content is research, not credentials. **No action.**

### Content grep (password|secret|api_key|token|credential)
- Hits are normal prose only: "OpenSecrets", "credentials" (candidate credentials), citation text. **No embedded secrets.**

### Verdict for prod/
- **No sensitive files or secrets detected.** Content is HTML dossiers, analyses, and primary-source pages.
- **Recommendation:** Keep prod/ to public-only content. Do not add `.env`, `.md` with secrets, or draft/backup files that shouldn’t be public. Run `./deploy.sh` only from a tree that excludes such files (e.g. a dedicated `prod/` export).

---

## Cross-Cutting Notes

1. **Cloudflare:** Tunnel terminates at Cloudflare; DDoS and edge TLS. No Cloudflare Access (JWT) on these routes — auth is at origin (Authelia / app OIDC).
2. **Caddy:** Single entry point; forward_auth and reverse_proxy only. No dynamic code.
3. **OIDC vs forward_auth:** Immich, Headscale, Jellyfin use OIDC at the app (no forward_auth). All others use forward_auth so unauthenticated users never reach the app.
4. **Subdomain enumeration:** An attacker can guess other hostnames (e.g. sso, nas, n8n). Each is either gated (forward_auth) or app-authenticated (OIDC). No service is “open” except politics.

---

## Recommendations

| Priority | Action |
|----------|--------|
| High | Ensure Authelia 2FA for users who can reach nas/n8n when on LAN or VPN. |
| Medium | Optional: Enable Cloudflare Access (JWT) for politics if you want an extra gate without changing the static site. |
| Low | WAF or rate limiting on `*.xcvr.link` in Cloudflare to slow probing/abuse. |
| Ongoing | Keep Caddy, Authelia, and all app stacks updated; review Authelia and app logs periodically. |

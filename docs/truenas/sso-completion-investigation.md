# SSO Completion Investigation: Exposing nas.xcvr.link

**Purpose:** Identify what's needed to finish SSO setup so nas.xcvr.link (and rules.xcvr.link) can be safely exposed to the internet.

**References:** [sso-setup-walkthrough.md](sso-setup-walkthrough.md), [truenas-apps-sso-and-updates.md](truenas-apps-sso-and-updates.md), [cloudflare-tunnel-direct-routes.md](../networking/cloudflare-tunnel-direct-routes.md)

---

## TL;DR – What's Done vs. What's Left

| Item | Status |
|------|--------|
| Authelia installed | ✅ Running (port 30133) |
| sso.xcvr.link in NPM | ✅ Points to authelia:30133 |
| rules.xcvr.link in NPM | ✅ Points to 192.168.0.158:30081 |
| nas.xcvr.link in NPM | ❌ **Missing** – add Proxy Host with auth_request |
| Cloudflare Tunnel routes | ❓ **Check in Cloudflare dashboard** – sso, nas, rules need to point to `http://192.168.0.158:80` |
| NPM proxy port | ✅ Port 80 (and 443) |

**Next steps:** 1) Add nas.xcvr.link Proxy Host in NPM (with Authelia auth_request). 2) In Cloudflare Zero Trust → Tunnels, verify/add routes for sso, nas, rules → `http://192.168.0.158:80`.

---

## Current State (Verified via Browser + SSH, 2026-02-02)

| Component | Status |
|-----------|--------|
| **Cloudflare Tunnel** | Running (cloudflared-xcvr); routes Immich, Syncthing, n8n directly to app ports |
| **nas.xcvr.link** | **No NPM Proxy Host** – not in NPM; tunnel status unknown |
| **rules.xcvr.link** | NPM Proxy Host exists → `http://192.168.0.158:30081`; SSL: HTTP Only; Public; Online |
| **sso.xcvr.link** | NPM Proxy Host exists → `http://authelia:30133`; SSL: HTTP Only; Public; Online |
| **Nginx Proxy Manager** | Installed; admin at 30020; **proxy ports 80 and 443** (receives traffic) |
| **Authelia** | Installed and running; port **30133** (not 9091); NPM points sso.xcvr.link to it |

---

## What Needs to Happen (Order of Operations)

### 1. Install and Configure Authelia

**Status: ✅ Installed and running.** Authelia is on port **30133** (NPM already points sso.xcvr.link → authelia:30133).

**Verify config:** Ensure `configuration.yml` and `users_database.yml` exist at `/mnt/tank/apps/authelia` (or Authelia's config path). If sso.xcvr.link login works, config is likely correct.

If **not installed** (skip – already done):
- Apps → Discover → enable **Community** train → search "Authelia" → Install
- Or: Install via YAML (see [sso-setup-walkthrough.md §2](sso-setup-walkthrough.md#step-2-install-authelia-via-yaml-if-not-in-catalog))
- Port: 9091
- Storage: `/mnt/tank/apps/authelia` (or ix volume)

**Configure Authelia** (Step 3 of walkthrough):
- Create `configuration.yml` and `users_database.yml` in Authelia's config path
- Set `authelia_url: https://sso.xcvr.link`, session domain `xcvr.link`
- Add at least one user (argon2 hash via `authelia crypto hash generate argon2`)
- Restart Authelia

### 2. NPM: Proxy Host for sso.xcvr.link

**Status: ✅ Done.** sso.xcvr.link → `http://authelia:30133`; Public; Online. Consider enabling SSL (Let's Encrypt) in NPM for sso.xcvr.link if not already.

### 3. Cloudflare Tunnel: Route sso.xcvr.link → NPM

**NPM proxy port (verified):** Port **80** (and 443) – NPM receives proxied traffic on these.

**Add tunnel route** (check in Cloudflare Zero Trust dashboard):
- Zero Trust → Networks → Tunnels → `cloudflared-xcvr` (or your tunnel name) → Public Hostnames
- Add if missing: `sso` / `xcvr.link` → `http://192.168.0.158:80`
- DNS is usually auto-created when you add a tunnel hostname

### 4. Test sso.xcvr.link

- Visit https://sso.xcvr.link
- Should see Authelia login; log in with configured user

### 5. NPM: Proxy Host for nas.xcvr.link (with auth_request) — **TODO**

**Status: ❌ Missing.** No nas.xcvr.link Proxy Host in NPM.

**Add:**
- **Domain:** nas.xcvr.link
- **Forward to:** `192.168.0.158:81` (TrueNAS Web UI)
- **SSL:** Let's Encrypt
- **Advanced:** Add Authelia `auth_request` snippets so unauthenticated users are redirected to sso.xcvr.link. Use `authelia:30133` in snippets (not 9091).

See [Authelia NPM auth_request snippets](https://www.authelia.com/integration/proxies/nginx-proxy-manager/).

### 6. Cloudflare Tunnel: Route nas.xcvr.link → NPM

- Add: `nas` / `xcvr.link` → `http://192.168.0.158:80`

### 7. rules.xcvr.link (Optional: With or Without SSO)

**NPM:** ✅ Proxy Host exists (→ 30081). **Tunnel route:** Add `rules` / `xcvr.link` → `http://192.168.0.158:80` if you want rules.xcvr.link reachable from the internet (for Cursor indexing). rules can stay public (no auth_request) since it's docs.

---

## Verification Checklist

| Step | Action | Verify |
|------|--------|--------|
| 1a | Authelia installed | Apps → Installed shows authelia, status Running |
| 1b | Authelia configured | `configuration.yml` and `users_database.yml` exist; Authelia starts without errors |
| 2 | NPM sso.xcvr.link host | NPM Proxy Hosts shows sso.xcvr.link → authelia:9091 |
| 3 | Tunnel sso route | Tunnel Public Hostnames includes sso.xcvr.link → NPM port |
| 4 | sso.xcvr.link works | https://sso.xcvr.link shows Authelia login |
| 5 | NPM nas.xcvr.link host | NPM Proxy Hosts shows nas.xcvr.link → 192.168.0.158:81 with auth_request |
| 6 | Tunnel nas route | Tunnel Public Hostnames includes nas.xcvr.link → NPM port |
| 7 | nas.xcvr.link works | https://nas.xcvr.link redirects to sso login, then to TrueNAS UI |

---

## Quick Status Check Commands

From your Mac (SSH to NAS):

```bash
# Is Authelia running?
ssh truenas_admin@192.168.0.158 'curl -s -o /dev/null -w "%{http_code}" http://localhost:9091/api/state 2>/dev/null || echo "Authelia not reachable"'

# List Apps (need TrueNAS API or UI)
# Check NPM proxy ports in TrueNAS UI: Apps → Nginx Proxy Manager → Workloads
```

---

## Summary: Minimum to Expose nas.xcvr.link

1. **Authelia** – Install, configure, create user
2. **NPM** – sso.xcvr.link → Authelia; nas.xcvr.link → TrueNAS:81 (with auth_request)
3. **Cloudflare Tunnel** – sso.xcvr.link and nas.xcvr.link → NPM's HTTP proxy port
4. **DNS** – CNAME records for sso and nas (Cloudflare often creates these when you add tunnel routes)

Once sso.xcvr.link works, add nas.xcvr.link with auth_request, then add the tunnel route. rules.xcvr.link can be added the same way if you want it behind SSO, or left public if it's documentation-only.

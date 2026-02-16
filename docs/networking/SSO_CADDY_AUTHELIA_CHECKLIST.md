# SSO (Authelia) + Caddy on Pi 5 — Checklist

**Goal:** All `*.xcvr.link` services (except the SSO portal) require login via Authelia. Caddy on the Pi does `forward_auth` to Authelia on TrueNAS before proxying to each app.

**OIDC / trusted headers:** For a hybrid setup (OIDC for Immich, Headscale, Jellyfin; trusted headers for Navidrome), see [SSO_SERVICE_MATRIX.md](SSO_SERVICE_MATRIX.md).

---

## 1. Verify Authelia is reachable

- **From your Mac (LAN):**
  ```bash
  curl -sI http://192.168.0.158:30133/
  ```
  Expect **200** or **302** (not connection refused).

- **In a browser:** Open **https://sso.xcvr.link**. You should see the Authelia login page (or a redirect to it). If you get 502 or connection errors, Caddy can’t reach Authelia — check Pi → TrueNAS connectivity and that the Authelia app is running on TrueNAS.

---

## 2. Authelia configuration (on TrueNAS)

**Catalog app:** The catalog form does **not** expose session domain, Authelia URL, or default redirection URL. You must edit `configuration.yml` on the Config Storage ixVolume (see [authelia-catalog-config.md](truenas/authelia-catalog-config.md)). **Important:** If **“Use Dummy Configuration”** is checked in Authelia Configuration, uncheck it so Authelia uses the real config files; then add a proper `configuration.yml` and `users_database.yml` to the config volume.

Authelia’s config lives in the app’s storage (e.g. `/mnt/.../authelia` or the ix volume for `/config`). You need **two files**: `configuration.yml` and `users_database.yml`.

**Required in `configuration.yml`:**

- **Session / cookies** (so the cookie works across `*.xcvr.link`):
  - `session.domain`: `xcvr.link`
  - Under `session.cookies` (list): `domain: xcvr.link`, `authelia_url: https://sso.xcvr.link`, `default_redirection_url: https://sso.xcvr.link`

- **Access control** (who can access what):
  - `access_control.default_policy`: `deny`
  - Rules: e.g. `domain: sso.xcvr.link` → `one_factor`; `domain: "*.xcvr.link"` → `one_factor` (or `two_factor` if you use 2FA)

- **Forward-auth (required for Caddy):**
  - Under `server.endpoints.authz` set the forward-auth implementation. In recent Authelia versions the default is already `ForwardAuth`; if not, add:
    ```yaml
    server:
      endpoints:
        authz:
          forward-auth:
            implementation: ForwardAuth
    ```

- **Authentication backend:** e.g. `file` with `path: /config/users_database.yml`

**`users_database.yml`:** At least one user with an Argon2-hashed password (see [sso-setup-walkthrough.md](truenas/sso-setup-walkthrough.md) for `authelia crypto hash generate argon2`).

Restart the Authelia app after editing config.

---

## 3. Caddy: forward_auth (done in Caddyfile)

The Caddyfile in this repo is set up so that **every host except `sso.xcvr.link`** uses `forward_auth` to Authelia at `192.168.0.158:30133` before `reverse_proxy`—**except** Immich, Headscale, and Jellyfin, which use OIDC (no forward_auth; app handles auth). See [SSO_SERVICE_MATRIX.md](SSO_SERVICE_MATRIX.md) for OIDC setup.

- **sso.xcvr.link** → no forward_auth (portal; login page).
- **immich, headscale, jellyfin** → OIDC (no forward_auth; configure OIDC in each app first).
- **nas, rules, n8n, syncthing, music, listen, watch, read** → forward_auth then reverse_proxy.

Deploy the updated Caddyfile: `./scripts/servarr-pi5-caddy-update.sh`.

---

## 4. Optional: Trusted proxies in Caddy

So Authelia sees the correct client IP and headers (e.g. when traffic comes via Cloudflare Tunnel or LAN), the Caddyfile includes a global `trusted_proxies` line. If you use only LAN + Tunnel, the suggested ranges are fine; tighten them if you have a different topology.

---

## 5. Test flow

1. Open an incognito/private window (or clear cookies for `xcvr.link`).
2. Go to e.g. **https://immich.xcvr.link**.
3. You should be redirected to **https://sso.xcvr.link**, log in, then be sent back to Immich.
4. Repeat for n8n, jellyfin, etc. **https://sso.xcvr.link** should always show the login page (no forward_auth on that host).

---

## 6. If something breaks

- **502 on sso.xcvr.link:** Caddy can’t reach Authelia. Check: Authelia app running on TrueNAS; from Pi: `curl -sI http://192.168.0.158:30133/`.
- **Redirect loop or 401 on protected apps:** Check Authelia `session.domain`, `authelia_url`, and `default_redirection_url`; cookie domain must be `xcvr.link` and URLs must match how you reach the site (e.g. `https://sso.xcvr.link`).
- **“Not authorized” after login:** Check Authelia `access_control` rules (domain and policy) and that the request host is what Authelia expects.
- **“There was an issue retrieving the current user state” (red banner on login page):** Authelia’s frontend can’t resolve the request URL or session. Fix: (1) In Authelia `configuration.yml`, under `session.cookies` ensure `authelia_url: https://sso.xcvr.link` and `default_redirection_url: https://sso.xcvr.link` (no trailing path unless you use a subpath). See **Reference:** [authelia-session-config-reference.yml](truenas/authelia-session-config-reference.yml). To try to locate and show your config from the Mac: `./scripts/truenas/authelia-verify-config.sh` (requires truenas-sudo in keychain; if the script can’t find the file, get the config path from TrueNAS → Apps → authelia → Edit → Volume Mounts). (2) Ensure the proxy (Caddy) sends `X-Forwarded-Host` and `X-Forwarded-Proto` to Authelia; the Caddyfile for `sso.xcvr.link` includes explicit `header_up` for these. (3) Restart Authelia after config changes; redeploy Caddy if you changed the Caddyfile.

See also: [truenas-apps-sso-and-updates.md](truenas/truenas-apps-sso-and-updates.md), [sso-setup-walkthrough.md](truenas/sso-setup-walkthrough.md), [Authelia – Caddy](https://www.authelia.com/integration/proxies/caddy/).

---

## 7. SSL_ERROR_INTERNAL_ERROR_ALERT on https://sso.xcvr.link

**Symptom:** Browser shows "Secure Connection Failed", "Peer reports it experienced an internal error", SSL_ERROR_INTERNAL_ERROR_ALERT.

**What it means:** The TLS handshake failed. The "peer" is either (a) **Cloudflare** if you’re on the internet, or (b) **Caddy** if you’re on LAN (DNS resolves sso.xcvr.link → 192.168.0.136).

**Most likely (LAN):** You’re hitting Caddy directly. Caddy doesn’t yet have a valid certificate for `sso.xcvr.link` (ACME/Let’s Encrypt didn’t complete), so the TLS handshake fails with an internal error.

**What to do:**

1. **Check Caddy logs on the Pi**  
   `ssh pi@192.168.0.136 'sudo docker logs caddy 2>&1 | tail -60'`  
   Look for ACME/certificate errors (e.g. "certificate obtain failed", "challenge failed").

2. **Let Let’s Encrypt reach Caddy (HTTP-01)**  
   Validation uses `http://sso.xcvr.link/.well-known/acme-challenge/...`. That request goes: Let’s Encrypt → Cloudflare → Tunnel → Caddy. In Cloudflare:
   - **SSL/TLS** → set to **Full** (not "Full (strict)" for now).
   - **Rules** → **Configuration Rules** (or Page Rules): add a rule so `*sso.xcvr.link/.well-known/acme-challenge/*` (or `*xcvr.link/.well-known/*`) **bypasses cache** and, if you use "Always Use HTTPS", **does not redirect** that path to HTTPS (so HTTP is allowed for the challenge). That way LE can validate and Caddy can get the cert.

3. **Trigger cert issuance**  
   After the rule is in place, restart Caddy so it retries ACME:  
   `ssh pi@192.168.0.136 'sudo docker restart caddy'`  
   Wait 1–2 minutes, then try https://sso.xcvr.link again (from LAN or internet).

4. **If it still fails**  
   - From the internet, try in a private window (to avoid cached TLS state).  
   - If you only ever use sso.xcvr.link from LAN and ACME can’t reach Caddy, options are: use **DNS-01** with Caddy’s Cloudflare DNS module, or put an exception in the browser for the self-signed cert (not ideal). Prefer fixing HTTP-01 (step 2) so Caddy gets a real cert.

---

## 8. ACME challenge failures from Caddy logs (behind Cloudflare)

When Caddy runs behind Cloudflare Tunnel, certificate issuance can fail in several ways. Interpreting `docker logs caddy`:

| Log pattern | Cause | Fix |
|-------------|--------|-----|
| `acme-staging-v02.api.letsencrypt.org` | Caddy is using Let’s Encrypt **staging**. Staging certs are not trusted by browsers. | Use **production** ACME. In the Caddyfile global `{ }` block set `acme_ca https://acme-v02.api.letsencrypt.org/directory`. Redeploy and restart Caddy. On the Pi, remove any env or config that points at staging. |
| `Cannot negotiate ALPN protocol "acme-tls/1"` (tls-alpn-01) | TLS ends at Cloudflare; LE cannot complete TLS-ALPN-01. | Normal when behind a proxy. Caddy will retry with HTTP-01. Ensure HTTP-01 can succeed (see below). |
| `NXDOMAIN looking up A for <host>.xcvr.link` | No public DNS record for that host. LE cannot reach it for HTTP-01. | In Cloudflare (or wherever xcvr.link is hosted), add a DNS record for every host (CNAME to tunnel or A/AAAA). e.g. **nas.xcvr.link**, **headscale.xcvr.link** must resolve. |
| `Invalid response from http://<host>/.well-known/acme-challenge/...: 530` | Cloudflare returns 530 (origin unreachable / error). The challenge request never reaches Caddy. | 1) **Tunnel:** Confirm the tunnel to the Pi is up and the service URL is correct (e.g. `http://localhost:80` or the Caddy port). 2) **Cloudflare:** Add a Configuration Rule (or Page Rule) so `*xcvr.link/.well-known/acme-challenge/*` **bypasses cache** and is **not** forced to HTTPS (allow HTTP for that path). 3) **SSL/TLS:** Set to **Full** (not Full (strict) until certs are issued). |

**Checklist for HTTP-01 behind Cloudflare:**

1. **Production CA** – Caddyfile global block has `acme_ca https://acme-v02.api.letsencrypt.org/directory` (no staging).
2. **Public DNS** – Every `*.xcvr.link` host used in the Caddyfile has a DNS record in Cloudflare (or your DNS) so LE can resolve and connect.
3. **Path reaches Caddy** – `http://<host>/.well-known/acme-challenge/<token>` returns 200 from Caddy (no 530). Tunnel healthy; Cloudflare rule allows HTTP for that path and bypasses cache.
4. **Restart and wait** – After changes: `ssh pi@192.168.0.136 'sudo docker restart caddy'`. Wait 1–2 minutes and recheck logs.

If 530 persists, consider **DNS-01** with a Caddy build that includes the Cloudflare DNS module, so Caddy can satisfy LE without HTTP to the origin.

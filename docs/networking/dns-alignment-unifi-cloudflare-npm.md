# DNS Alignment: UniFi Local DNS, Cloudflare, and NPM

**Purpose:** Single source of truth for aligning local DNS (UniFi), Cloudflare Tunnel routes, Cloudflare DNS records, and NPM proxy hosts for `xcvr.link` subdomains.

**Last updated:** 2026-01-31

---

## Quick Reference Table

| Subdomain | Local IP | UniFi Local DNS | Cloudflare Tunnel | NPM Proxy Host | Notes |
|-----------|----------|-----------------|-------------------|----------------|-------|
| sso | 192.168.0.136 | ✅ | ✅ → Caddy:80 | ✅ → authelia:30133 | SSO portal |
| nas | 192.168.0.158 | ✅ | ❌ local only | ✅ → 192.168.0.158:81 | TrueNAS UI; do not tunnel |
| headscale | 192.168.0.158 | ✅ | ✅ → Caddy:80 | ✅ → 192.168.0.158:30210 | Headscale (HTTPS) |
| rules | 192.168.0.158 | ✅ | ✅ → Caddy:80 | ✅ → 192.168.0.158:30081 | Rules docs |
| immich | 192.168.0.158 | ✅ | ✅ → Caddy:80 | ✅ → 192.168.0.158:30041 | Photos |
| n8n | 192.168.0.158 | ✅ | ❌ local only | ✅ → 192.168.0.158:30109 | Workflows; do not tunnel |
| syncthing | 192.168.0.158 | ✅ | ✅ → Caddy:80 | ✅ → 192.168.0.158:8334 | File sync |
| pi5 | 192.168.0.136 | ✅ | ❌ | ❌ | Pi 5 / Servarr stack; local only |
| jellyfin | 192.168.0.158 | ✅ | ✅ → Caddy:80 | ✅ | Jellyfin via Caddy → Pi 5:8096 |
| music | 192.168.0.158 | ✅ | ✅ → Caddy:80 | ✅ | Navidrome via Caddy → Pi 5:4533 |
| jet | 192.168.0.197 | ✅ | ✅ | ❌ | Jet KVM web UI |
| politics | 192.168.0.136 | ✅ | ✅ → Caddy → NAS:8765 | ❌ | Static site (Caddy container on TrueNAS :8765) |

---

## 1. UniFi Local DNS Records

**Where:** UniFi Network → Settings → Networks → [Your LAN] → DHCP → Local DNS Records

**Why:** LAN clients using UDM Pro DNS (192.168.0.1) resolve these hostnames to local IPs instead of going through Cloudflare. This keeps traffic on-LAN and avoids hairpinning.

**Add these records** (Hostname | Domain | IP Address | Type):

| Hostname | Domain | IP Address | Type |
|----------|--------|------------|------|
| sso | xcvr.link | 192.168.0.158 | A |
| nas | xcvr.link | 192.168.0.158 | A |
| headscale | xcvr.link | 192.168.0.158 | A |
| rules | xcvr.link | 192.168.0.158 | A |
| immich | xcvr.link | 192.168.0.158 | A |
| n8n | xcvr.link | 192.168.0.158 | A |
| syncthing | xcvr.link | 192.168.0.158 | A |
| pi5 | xcvr.link | 192.168.0.136 | A |
| jellyfin | xcvr.link | 192.168.0.158 | A |
| music | xcvr.link | 192.168.0.158 | A |
| jet | xcvr.link | 192.168.0.197 | A |
| politics | xcvr.link | 192.168.0.136 | A |

**UniFi UI steps:**
1. Settings → Networks → Local Networks
2. Click your LAN network (e.g. "Default")
3. DHCP tab → scroll to **Local DNS Records**
4. Add each row above (Hostname, Domain, IP Address)
5. Save

**Via SSH (automated):**
```bash
./unifi/add-local-dns-via-ssh.sh
```
Requires `unifi/.env` with `UNIFI_SSH_USER`, `UNIFI_SSH_HOST`, and optionally `UNIFI_SSH_PASSWORD`. Uses `ubios-udapi-client` on the UDM Pro. Note: host records may be overwritten by UniFi after firmware updates or network config changes; re-run if DNS stops resolving. If `music.xcvr.link` (or others) don’t resolve, re-run this script to re-apply all records.

**Seamless (LAN + Tailscale):** To have xcvr.link work whether on LAN or remote via Tailscale, add the same records to Headscale MagicDNS. See **`headscale-xcvr-dns-seamless.md`**.

---

## 2. Cloudflare Tunnel: Published Application Routes

**Where:** Cloudflare Dashboard → Zero Trust → Networks → Tunnels → [Your tunnel] → Public Hostnames

**Public hostnames only.** Do **not** add tunnel routes for `nas`, `n8n`, `pi5`, or `jet` (local-only; access via LAN or VPN/Headscale).

| Subdomain | Domain | Service URL |
|-----------|--------|-------------|
| sso | xcvr.link | `http://192.168.0.136:80` |
| headscale | xcvr.link | `http://192.168.0.136:80` |
| rules | xcvr.link | `http://192.168.0.136:80` |
| immich | xcvr.link | `http://192.168.0.136:80` |
| syncthing | xcvr.link | `http://192.168.0.136:80` |
| jellyfin | xcvr.link | `http://192.168.0.136:80` |
| music | xcvr.link | `http://192.168.0.136:80` |
| listen | xcvr.link | `http://192.168.0.136:80` |
| watch | xcvr.link | `http://192.168.0.136:80` |
| read | xcvr.link | `http://192.168.0.136:80` |
| politics | xcvr.link | `https://192.168.0.136` (Origin Server Name: politics.xcvr.link; No TLS Verify) |

---

## 3. Cloudflare DNS Records (Public)

**Where:** Cloudflare Dashboard → DNS → Records

For tunneled subdomains, Cloudflare typically creates CNAME records automatically when you add public hostnames to the tunnel. Verify:

| Type | Name | Content | Proxy |
|------|------|---------|-------|
| CNAME | sso | `your-tunnel.cfargotunnel.com` | Proxied |
| CNAME | headscale | `your-tunnel.cfargotunnel.com` | Proxied |
| CNAME | rules | `your-tunnel.cfargotunnel.com` | Proxied |
| CNAME | immich | `your-tunnel.cfargotunnel.com` | Proxied |
| CNAME | syncthing | `your-tunnel.cfargotunnel.com` | Proxied |
| CNAME | jellyfin | `your-tunnel.cfargotunnel.com` | Proxied |
| CNAME | music | `your-tunnel.cfargotunnel.com` | Proxied |

For **nas** and **n8n**: do not create tunnel routes; remove any existing CNAME (or public hostname) so they are not reachable from the public internet. UniFi Local DNS still resolves them on-LAN.

For `pi5` and `jet`: if you want them resolvable from outside (e.g. via DDNS), add A records pointing to your home IP. Otherwise leave them out of Cloudflare DNS; UniFi Local DNS handles them on-LAN only.

---

## 4. NPM Proxy Hosts

**Where:** NPM Admin UI → `http://192.168.0.158:30020` → Proxy Hosts

**Current configuration** (from `npm-routing-test-results.md` and `truenas-app-service-urls.md`):

| Domain | Forwards To | SSL |
|--------|-------------|-----|
| sso.xcvr.link | authelia:30133 | HTTP Only (or Let's Encrypt) |
| nas.xcvr.link | 192.168.0.158:81 | HTTP Only |
| headscale.xcvr.link | 192.168.0.158:30210 | Let's Encrypt (for Tailscale app) |
| rules.xcvr.link | 192.168.0.158:30081 | HTTP Only |
| immich.xcvr.link | 192.168.0.158:30041 | HTTP Only |
| n8n.xcvr.link | 192.168.0.158:30109 | HTTP Only |
| syncthing.xcvr.link | 192.168.0.158:8334 | HTTP Only |
| jellyfin.xcvr.link | 192.168.0.136:8096 | HTTP Only |
| music.xcvr.link | 192.168.0.136:4533 | HTTP Only |

**Port 80 requirement:** NPM must bind to port 80 for tunnel traffic. If TrueNAS occupies 80/443, change TrueNAS web ports (e.g. HTTP→81, HTTPS→444) so NPM can use 80/443. See `docs/truenas/npm-routing-test-results.md`.

---

## 5. Verification Checklist

### Local DNS (from Mac on LAN)

```bash
# Ensure Mac uses UDM Pro DNS (192.168.0.1), not Tailscale (100.100.100.100)
# System Settings → Network → DNS

# All should resolve to expected IPs (empty = no result)
for h in sso nas immich pi5 jet; do r=$(dig +short $h.xcvr.link); echo "$h.xcvr.link: ${r:-no result}"; done
```

### NPM routing (from Mac on LAN)

```bash
# Should return 200 or proxy response, NOT 302 to /ui/
curl -sI -m 5 -w "Exit: %{exitcode}\n" -H "Host: rules.xcvr.link" http://192.168.0.158:80/ 2>&1 | head -6
curl -sI -m 5 -w "Exit: %{exitcode}\n" -H "Host: immich.xcvr.link" http://192.168.0.158:80/ 2>&1 | head -6
```

### External access (from phone off-Wi‑Fi or different network)

```bash
# Should work via Cloudflare Tunnel
curl -sI -m 5 -w "Exit: %{exitcode}\n" https://immich.xcvr.link 2>&1 | head -6
curl -sI -m 5 -w "Exit: %{exitcode}\n" https://sso.xcvr.link 2>&1 | head -6
```

---

## 6. Future Subdomains (Not Yet Deployed)

| Subdomain | Target IP | Purpose |
|-----------|-----------|---------|
| listen.xcvr.link | 192.168.0.158 | NPM → Navidrome (music) or Audiobookshelf; same as music if merged |
| watch.xcvr.link | 192.168.0.158 | NPM → Jellyfin (movies/TV); same as jellyfin if merged |
| read.xcvr.link | 192.168.0.158 | NPM → Audiobookshelf (ebooks) when deployed |
| headscale.xcvr.link | 192.168.0.158 | Headscale UI (optional) |

When deployed, add corresponding UniFi Local DNS, Cloudflare Tunnel, and NPM entries per the tables above.

---

## 7. Related Docs

- **`npmplus-dns-tunnel-diagram-and-verification.md`** — Diagram (Mermaid), port table, NPM+ proxy list, and verification results
- `cloudflare-tunnel-direct-routes.md` — Tunnel + NPM architecture
- `truenas-app-service-urls.md` — TrueNAS app ports
- `npm-routing-test-results.md` — NPM port 80 fix, proxy host list
- `unifi-dns-troubleshooting.md` — DNS resolution issues
- `local-dns-caddy-flow.md` — How local DNS + reverse proxy work (Caddy example; NPM analogous)

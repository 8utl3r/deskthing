# Network Reference — Complete Guide

**Purpose:** Single reference for another agent or human to understand and operate this network. Covers DNS, Cloudflare, reverse proxy, credentials, and verification.

**Last updated:** 2026-02-11

---

## 1. Overview

| Component | Role |
|-----------|------|
| **Domain** | `xcvr.link` — all services use `*.xcvr.link` subdomains |
| **DNS (LAN)** | UniFi UDM Pro (192.168.0.1) Local DNS records |
| **DNS (Remote)** | Cloudflare public DNS + Headscale MagicDNS for Tailscale |
| **External access** | Cloudflare Zero Trust Tunnel → Caddy on Pi 5 |
| **Reverse proxy** | Caddy on Pi 5 (192.168.0.136) port 80/443 |
| **Internal services** | TrueNAS apps (192.168.0.158), Pi 5 (192.168.0.136) |

Flow: `https://subdomain.xcvr.link` → Cloudflare → Tunnel → Caddy on Pi 5 (80) → backend by hostname.

---

## 2. IP Inventory

| Device | IP | Hostname/DNS | Notes |
|--------|-----|--------------|-------|
| **UDM Pro** | 192.168.0.1 | gateway | Router, DHCP, Local DNS |
| **TrueNAS** | 192.168.0.158 | nas, headscale, sso, rules, immich, n8n, syncthing (backends) | UGREEN DXP2800; backends for Caddy |
| **Pi 5 (Servarr)** | 192.168.0.136 | pi5, jellyfin, music, listen, watch, read; Caddy reverse proxy | Jellyfin, Navidrome, *arr stack; Caddy on 80/443 |
| **Jet KVM** | 192.168.0.197 | jet | KVM web UI (http://192.168.0.197) |
| **Windows PC** | 192.168.0.47 | — | Ugoos SK1 flashing, AML Burning Tool |
| **Mac** | DHCP | — | Primary workstation |

---

## 3. Domain and DNS

### 3.1 UniFi Local DNS Records

**Where:** UniFi Network → Settings → Networks → [LAN] → DHCP → Local DNS Records

**Why:** LAN clients using UDM Pro DNS (192.168.0.1) resolve `*.xcvr.link` to local IPs. Keeps traffic on-LAN.

| Hostname | Domain | IP Address | Type |
|----------|--------|------------|------|
| sso | xcvr.link | 192.168.0.136 | A |
| nas | xcvr.link | 192.168.0.136 | A |
| headscale | xcvr.link | 192.168.0.136 | A |
| rules | xcvr.link | 192.168.0.136 | A |
| immich | xcvr.link | 192.168.0.136 | A |
| n8n | xcvr.link | 192.168.0.136 | A |
| syncthing | xcvr.link | 192.168.0.136 | A |
| pi5 | xcvr.link | 192.168.0.136 | A |
| jellyfin | xcvr.link | 192.168.0.136 | A |
| music | xcvr.link | 192.168.0.136 | A |
| listen | xcvr.link | 192.168.0.136 | A |
| watch | xcvr.link | 192.168.0.136 | A |
| read | xcvr.link | 192.168.0.136 | A |
| jet | xcvr.link | 192.168.0.197 | A |

**Automated:** `./unifi/add-local-dns-via-ssh.sh` — applies all records via SSH + ubios-udapi-client. Re-run after UniFi firmware updates (records may be overwritten).

### 3.2 Headscale MagicDNS (Tailscale)

When using Tailscale with Headscale, add the same A records to Headscale so `*.xcvr.link` resolves whether on LAN or remote.

**File:** `headscale/extra-records-xcvr.json`

**TrueNAS path:** `/mnt/tank/apps/headscale/extra-records.json` (if Headscale supports dynamic JSON)

**Records:** Same as UniFi table above. See `docs/networking/headscale-xcvr-dns-seamless.md`.

---

## 4. Cloudflare Setup

### 4.1 Zero Trust Tunnel

**Where:** Cloudflare Dashboard → Zero Trust → Networks → Tunnels

**Tunnel:** `cloudflared` runs on TrueNAS. Token in `cloudflared/.env` (gitignored). TrueNAS reads from `/mnt/tank/apps/cloudflared/.env`. See `cloudflared/README.md` for setup and rotation.

**Published routes (all → Caddy on Pi 5 port 80):**

| Subdomain | Domain | Service URL |
|-----------|--------|-------------|
| sso | xcvr.link | http://192.168.0.136:80 |
| nas | xcvr.link | http://192.168.0.136:80 |
| headscale | xcvr.link | http://192.168.0.136:80 |
| rules | xcvr.link | http://192.168.0.136:80 |
| immich | xcvr.link | http://192.168.0.136:80 |
| n8n | xcvr.link | http://192.168.0.136:80 |
| syncthing | xcvr.link | http://192.168.0.136:80 |
| jellyfin | xcvr.link | http://192.168.0.136:80 |
| music | xcvr.link | http://192.168.0.136:80 |

Optionally add listen, watch, read with Service URL `http://192.168.0.136:80` if exposed. **Do not add** tunnel routes for `pi5` or `jet` (local-only).

### 4.2 Cloudflare DNS Records

**Where:** Cloudflare Dashboard → DNS → Records

Tunnel hostnames are CNAME to `*.cfargotunnel.com`, Proxied. Cloudflare typically creates these when you add public hostnames to the tunnel. Verify one CNAME per subdomain above.

---

## 5. Caddy (Reverse Proxy on Pi 5)

**Where:** Pi 5 (192.168.0.136), Docker container; Caddyfile at `scripts/servarr-pi5/caddy/Caddyfile` in dotfiles, deployed to `/var/lib/caddy/config/Caddyfile` on the Pi.

**Proxy ports:** 80, 443 (receives tunnel + LAN traffic). Update Caddyfile and run `./scripts/servarr-pi5-caddy-update.sh` to deploy.

### 5.1 Proxy Hosts (Caddyfile server blocks)

| Domain | Forwards To | Notes |
|--------|-------------|-------|
| sso.xcvr.link | 192.168.0.158:30133 | Authelia |
| nas.xcvr.link | 192.168.0.158:81 | TrueNAS UI |
| headscale.xcvr.link | 192.168.0.158:30210 | Headscale |
| rules.xcvr.link | 192.168.0.158:30081 | Static rules docs |
| immich.xcvr.link | 192.168.0.158:30041 | Photos |
| n8n.xcvr.link | 192.168.0.158:30109 | Workflows |
| syncthing.xcvr.link | 192.168.0.158:8334 | File sync |
| jellyfin.xcvr.link | 192.168.0.136:8096 | Jellyfin on Pi 5 |
| music.xcvr.link | 192.168.0.136:4533 | Navidrome on Pi 5 |
| listen.xcvr.link, watch.xcvr.link, read.xcvr.link | 192.168.0.136:8096 | Jellyfin on Pi 5 |

**Note:** Caddy runs in Docker on the Pi; use Pi 5 host IP (192.168.0.136) for jellyfin/music/listen/watch/read so the container can reach host-published ports.

---

## 6. Port Assignments

### TrueNAS (192.168.0.158)

| Port | Service |
|------|---------|
| 81 | TrueNAS UI |
| 30133 | Authelia (SSO) |
| 30081 | rules-static |
| 30041 | Immich |
| 30109 | n8n |
| 8334 | Syncthing |
| 30210 | Headscale |

### Pi 5 (192.168.0.136)

| Port | Service |
|------|---------|
| 80, 443 | Caddy (reverse proxy) |
| 8096 | Jellyfin |
| 4533 | Navidrome |
| 9696 | Prowlarr |
| 8989 | Sonarr |
| 7878 | Radarr |
| 8686 | Lidarr |
| 5299 | LazyLibrarian |
| 6767 | Bazarr |
| 9117 | Jackett |
| 8191 | FlareSolverr |
| 8080 | qBittorrent |
| 5055 | Jellyseerr |

---

## 7. Credentials and .env Files

### 7.1 Credential Locations

| Purpose | File | Variables | Notes |
|---------|------|------------|-------|
| **UniFi SSH** | `unifi/.env` | `UNIFI_SSH_USER`, `UNIFI_SSH_HOST`, `UNIFI_SSH_PASSWORD` | Copy from `unifi/.env.example`. For `add-local-dns-via-ssh.sh` |
| **Cloudflare Tunnel** | `cloudflared/.env` | `TUNNEL_TOKEN` | Copy from `cloudflared/.env.example`. Deploy to TrueNAS with `./scripts/cloudflared/deploy-env-to-truenas.sh` |
| **NPM+ API** (retired) | `scripts/npm/.env` | Legacy; NPM+ replaced by Caddy on Pi 5. See `scripts/npm/README.md`. |
| **TrueNAS sudo** | `factorio/.env.nas` | `NAS_SUDO_PASSWORD`, `TRUENAS_USER`, `TRUENAS_HOST` | For `truenas_admin` sudo on TrueNAS. Used by all `scripts/truenas/*.sh` |
| **Headscale CLI** | `headscale/.env` | `HEADSCALE_CLI_ADDRESS`, `HEADSCALE_CLI_API_KEY`, `HEADSCALE_CLI_INSECURE` | Copy from `headscale/.env.example` |

### 7.2 .env File Paths

```
dotfiles/
├── unifi/.env                    # UniFi SSH
├── cloudflared/.env              # Cloudflare Tunnel token
├── scripts/npm/.env              # NPM+ API
├── factorio/.env.nas             # TrueNAS sudo
└── headscale/.env                # Headscale CLI
```

### 7.3 Keychain (Alternative to .env)

Scripts can use macOS Keychain via `scripts/credentials/creds.sh`. See `scripts/credentials/README.md`.

| Key | Source | Used by |
|-----|--------|---------|
| NPM | keychain | npm-api.sh (legacy; NPM+ retired) |
| NPM_EMAIL | keychain | npm-api.sh (legacy) |
| truenas-sudo | keychain | truenas SSH scripts |
| unifi-ssh | keychain | unifi scripts |

### 7.4 One-Time Setup

```bash
# UniFi
cp unifi/.env.example unifi/.env
# Edit: UNIFI_SSH_USER, UNIFI_SSH_HOST, UNIFI_SSH_PASSWORD

# Cloudflare Tunnel
cp cloudflared/.env.example cloudflared/.env
# Edit: TUNNEL_TOKEN (from Cloudflare → Zero Trust → Tunnels → Configure)
# Deploy to TrueNAS: ./scripts/cloudflared/deploy-env-to-truenas.sh

# NPM (retired — Caddy on Pi 5 is the reverse proxy; scripts/npm/ kept for reference)
# cp scripts/npm/.env.example scripts/npm/.env  # only if using legacy npm-api.sh

# TrueNAS
echo "NAS_SUDO_PASSWORD='your_sudo_password'" > factorio/.env.nas
# Optional: TRUENAS_USER=truenas_admin, TRUENAS_HOST=192.168.0.158

# Headscale
cp headscale/.env.example headscale/.env
# Edit: HEADSCALE_CLI_API_KEY (from headscale apikeys create)
```

---

## 8. Scripts and Automation

### 8.1 DNS

| Script | Purpose |
|--------|---------|
| `./unifi/add-local-dns-via-ssh.sh` | Add all xcvr.link Local DNS records to UDM Pro via SSH. Requires `unifi/.env` |

### 8.2 Caddy (reverse proxy on Pi 5)

| Script | Purpose |
|--------|---------|
| `./scripts/servarr-pi5-caddy-update.sh` | Deploy Caddyfile to Pi 5 and restart Caddy |
| `./scripts/caddy/verify-caddy-hosts.sh` | Verify each Caddy proxy host responds (curl with Host header to 192.168.0.136) |

### 8.3 TrueNAS

| Script | Purpose |
|--------|---------|
| `factorio/nas_sudo.sh 'docker ps -a'` | Run command with sudo on TrueNAS |

---

## 9. Verification Commands

Run from Mac on LAN. Ensure Mac uses UDM Pro DNS (192.168.0.1), not Tailscale (100.100.100.100), when testing local DNS.

### 9.1 Local DNS

```bash
for h in sso nas headscale rules immich n8n syncthing pi5 jellyfin music listen watch read jet; do
  r=$(dig +short $h.xcvr.link 2>/dev/null | head -1)
  echo "$h.xcvr.link → ${r:-no result}"
done
```

### 9.2 Caddy proxy (Pi 5)

```bash
./scripts/caddy/verify-caddy-hosts.sh
```

### 9.3 External (off-Wi‑Fi)

```bash
curl -sI -m 5 https://immich.xcvr.link | head -5
curl -sI -m 5 https://sso.xcvr.link | head -5
```

### 9.4 Direct Backend

```bash
curl -sI -m 5 http://192.168.0.158:30133/   # Authelia
curl -sI -m 5 http://192.168.0.136:8096/   # Jellyfin
```

---

## 10. Troubleshooting

### 10.1 DNS not resolving

- **Mac using Tailscale DNS:** Either (a) System Settings → Network → DNS — remove 100.100.100.100, add 192.168.0.1, or (b) configure Headscale to use the router as DNS so Tailscale advertises 192.168.0.1 — see **`headscale-xcvr-dns-seamless.md`** § "Direct Tailscale DNS to use the router"
- **Missing records:** Re-run `./unifi/add-local-dns-via-ssh.sh`

### 10.2 sso.xcvr.link returns 502

Caddy on Pi 5 cannot reach Authelia on TrueNAS (192.168.0.158:30133). See `docs/networking/sso-authelia-502-deep-dive.md`. Ensure Pi 5 can reach 192.168.0.158; check Caddy logs.

### 10.3 music.xcvr.link no local DNS

Add `music` / `xcvr.link` / `192.168.0.136` in UniFi Local DNS, or re-run `./unifi/add-local-dns-via-ssh.sh` (music and all proxied hosts point to 192.168.0.136).

### 10.4 Caddy on Pi 5 unreachable

- From Mac: `curl -sI -H "Host: immich.xcvr.link" http://192.168.0.136`. If no response, SSH to Pi 5 and run `sudo docker ps` and `sudo docker logs caddy`.
- Deploy updated Caddyfile: `./scripts/servarr-pi5-caddy-update.sh`

### 10.5 Tunnel not connecting

- Check cloudflared logs in TrueNAS Apps
- Rotate tunnel token in Cloudflare if needed
- Verify tunnel is "Active" in Cloudflare Zero Trust

### 10.6 Port 80/443 on Pi 5

Caddy on Pi 5 binds 80 and 443. Ensure no other service on the Pi uses those ports. TrueNAS UI stays on 81/444; Caddy is only on the Pi.

---

## 11. Related Documentation

| Doc | Topic |
|-----|-------|
| `dns-alignment-unifi-cloudflare-npm.md` | Single alignment table |
| `npmplus-dns-tunnel-diagram-and-verification.md` | Mermaid diagram, verification |
| `cloudflare-tunnel-direct-routes.md` | Tunnel + Caddy architecture |
| `cloudflare-tunnel-setup-guide.md` | Initial tunnel setup |
| `headscale-xcvr-dns-seamless.md` | Headscale MagicDNS for xcvr.link |
| `headscale-agent-access.md` | Ensure agent can run Headscale scripts from Mac (SSH + keychain) |
| `udm-pro-headscale-subnet-router-guide.md` | UDM Pro as Tailscale subnet router |
| `headscale-cli-setup.md` | Headscale CLI from Mac |
| `headscale-connect-phone.md` | Connect iPhone/Android to Headscale (pete user) |
| `unifi-dns-troubleshooting.md` | DNS resolution issues |
| `sso-authelia-502-deep-dive.md` | SSO 502 analysis |
| `truenas-app-service-urls.md` | TrueNAS port reference |
| `scripts/credentials/README.md` | Credential helper (Keychain, Bitwarden) |

---

## 12. Quick Reference Card

| Item | Value |
|------|-------|
| Domain | xcvr.link |
| UDM Pro | 192.168.0.1 |
| TrueNAS | 192.168.0.158 |
| Pi 5 | 192.168.0.136 |
| Jet KVM | 192.168.0.197 |
| Caddy (Pi 5) | http://192.168.0.136 (reverse proxy; verify with scripts/caddy/verify-caddy-hosts.sh) |
| TrueNAS UI | http://192.168.0.158:81 |
| Cloudflare | Zero Trust → Tunnels → Public Hostnames |
| UniFi DNS | Networks → [LAN] → DHCP → Local DNS Records |

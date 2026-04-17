# Pi 5 Services via NAS NPM

**Summary:** Use the **existing NPM on the NAS** (192.168.0.158) to proxy Pi 5 services. No need to install NPM on the Pi.

---

## Flow

```
music.xcvr.link → DNS (192.168.0.158) → NPM → 192.168.0.136:4533 (Navidrome on Pi)
jellyfin.xcvr.link → DNS (192.168.0.158) → NPM → 192.168.0.136:8096 (Jellyfin on Pi)
```

All `*.xcvr.link` subdomains resolve to the NAS (192.168.0.158). NPM receives traffic on port 80 and routes by Host header to the right backend.

---

## Add Music Proxy

```bash
cd ~/dotfiles
source scripts/npm/.env   # or ensure NPM_TOKEN in .env
./scripts/npm/npm-api.sh add-music
```

---

## DNS Fixes (if entries are wrong)

### 1. UniFi Local DNS

All subdomains that route through NPM should resolve to **192.168.0.158** (the NAS):

| Hostname | Domain | IP |
|----------|--------|-----|
| jellyfin | xcvr.link | 192.168.0.158 |
| music | xcvr.link | 192.168.0.158 |


### 2. Cloudflare Tunnel (for external access)

Add `music` to Public Hostnames if you want https://music.xcvr.link from outside:

- Subdomain: `music`
- Domain: `xcvr.link`
- Service: `http://192.168.0.158:80`

---

## Verify

```bash
# List current NPM proxy hosts
./scripts/npm/npm-api.sh list

# Test music (after adding DNS and proxy)
curl -sI -m 5 -H "Host: music.xcvr.link" http://192.168.0.158/ | head -5
```

---

## Why Not NPM on the Pi?

- **NAS NPM already works** – Central reverse proxy for all xcvr.link services
- **Pi resources** – NPM adds ~100–200 MB RAM; Pi runs Jellyfin, *arr, etc.
- **Single point of config** – One NPM for NAS + Pi services
- **Cloudflare Tunnel** – Points to NAS:80; NPM routes by host. Adding Pi NPM would require a second tunnel or different architecture.

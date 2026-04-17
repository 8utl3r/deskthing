# Jellyfin via NPM (No Port Number)

**Goal:** Access Jellyfin at `http://jellyfin.xcvr.link` (no `:8096`).

**Flow:** jellyfin.xcvr.link → DNS (192.168.0.158) → NPM → 192.168.0.136:8096 (Jellyfin on Pi 5)

---

## Done

- ✅ **DNS:** jellyfin.xcvr.link → 192.168.0.158 (UDM Pro + Headscale)
- ✅ **NPM Proxy Host:** jellyfin.xcvr.link → 192.168.0.136:8096 (added via API)

---

## Manual Steps (if needed)

### Add Cloudflare Tunnel Route (for external access)

**Cloudflare Zero Trust** → **Networks** → **Tunnels** → your tunnel → **Public Hostnames**:

- **Subdomain:** `jellyfin`
- **Domain:** `xcvr.link`
- **Service:** `http://192.168.0.158:80`

---

## Verify

```bash
# DNS (should return 192.168.0.158)
r=$(dig +short jellyfin.xcvr.link); echo "jellyfin.xcvr.link: ${r:-no result}"

# HTTP (should return 200 or redirect to Jellyfin)
curl -sI -m 5 -w "Exit: %{exitcode}\n" http://jellyfin.xcvr.link 2>&1 | head -6
```

---

## API (re-add if needed)

```bash
./scripts/npm/npm-api.sh add-jellyfin
```

## WebSocket + buffering (required for streaming)

Jellyfin uses WebSockets for playback control and progress. If you use **jellyfin.xcvr.link** (via NPM), WebSocket must be enabled or debrid/streamed playback can fail (e.g. "fatal player error" or stream never starts). Enable in NPM:

```bash
./scripts/npm/npm-api.sh fix-jellyfin
```

Requires valid NPM_TOKEN in `scripts/npm/.env`. If token expired: NPM Admin → System → API → Generate new token.

## Verify full chain

```bash
./scripts/npm/verify-reverse-proxy.sh
```

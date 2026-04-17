# NPM Routing Test Results — 2026-02-03

## Test Summary

| Hostname           | Expected Backend        | Actual Result                          |
|--------------------|-------------------------|----------------------------------------|
| rules.xcvr.link    | rules-static (30081)    | 302 → `/ui/` (TrueNAS)                 |
| sso.xcvr.link      | Authelia (30133)        | 302 → `/ui/` (TrueNAS)                 |
| nas.xcvr.link      | TrueNAS (81)            | 302 → `/ui/` (TrueNAS)                 |
| immich.xcvr.link   | Immich (30041)          | 302 → `/ui/` (TrueNAS)                 |
| n8n.xcvr.link      | n8n (30109)             | 302 → `/ui/` (TrueNAS)                 |
| syncthing.xcvr.link| Syncthing (8334)        | 302 → `/ui/` (TrueNAS)                 |

## Direct Backend Verification

- **rules-static**: `http://192.168.0.158:30081` — works; serves Agent Rules index with links.
- **Port 80**: `http://192.168.0.158:80` — redirects to `http://192.168.0.158/ui/` (TrueNAS UI).

## Root Cause

**Port 80 is used by TrueNAS, not NPM.**

TrueNAS SCALE uses ports 80 and 443 by default for its web interface. All traffic to port 80 is handled by TrueNAS nginx, which redirects to `/ui/`. NPM proxy hosts are configured correctly but never receive traffic because NPM is not bound to port 80.

- NPM admin UI: `http://192.168.0.158:30020`
- NPM proxy ports: intended to be 80/443, but TrueNAS occupies them

## Fix Required

1. **Change TrueNAS web ports** so NPM can use 80/443:
   - System Settings → General → Web Interface
   - Set HTTP port to `81` (or another free port)
   - Set HTTPS port to `444` (or another free port)
   - Apply and restart services

2. **Configure NPM to bind to 80/443** (done 2026-02-03):
   - Updated `/mnt/.ix-apps/app_configs/nginx-proxy-manager/versions/1.2.27/user_config.yaml`: http_port 30021→80, https_port 30022→443
   - NPM runs as manual container. See `npm-manual-container-recovery.md` for recovery.

3. **Verify**:
   ```bash
   curl -sI -m 5 -w "Exit: %{exitcode}\n" -H "Host: rules.xcvr.link" http://192.168.0.158:80/ 2>&1 | head -6
   # Should return 200 or proxy to rules-static, not 302 to /ui/
   ```

## NPM Proxy Hosts (Current)

All six proxy hosts are correctly configured in NPM. For full DNS alignment (UniFi + Cloudflare + NPM), see `docs/networking/dns-alignment-unifi-cloudflare-npm.md`.

```
immich.xcvr.link → 192.168.0.158:30041
n8n.xcvr.link → 192.168.0.158:30109
nas.xcvr.link → 192.168.0.158:81
rules.xcvr.link → 192.168.0.158:30081
sso.xcvr.link → authelia:30133
syncthing.xcvr.link → 192.168.0.158:8334
```

# Remove Caddy

## Status: Deprecated – Caddy removed in favor of Cloudflare Tunnel direct routes.

## Remove Caddy on TrueNAS

1. **Go to:** TrueNAS Web UI → Apps → Installed Apps
2. **Find:** `caddy`
3. **Click:** Stop (if running)
4. **Click:** Delete (or three dots → Delete)
5. **Confirm** deletion

## Optional: Revert TrueNAS Web UI Ports

If you moved TrueNAS to port 81/444 for Caddy, you can revert to 80/443:

**In TrueNAS Shell:**
```bash
midclt call system.general.update '{"ui_port": 80, "ui_httpsport": 443}'
```

Then access TrueNAS at `http://192.168.0.158` again.

**Or keep 81/444** – either works. Cloudflare Tunnel routes `nas.xcvr.link` to port 81.

## Current Access (After Caddy Removal)

- **External (Cloudflare Tunnel):** `https://immich.xcvr.link`, `https://syncthing.xcvr.link`, `https://n8n.xcvr.link` (direct to each service). **nas.xcvr.link is not published** – TrueNAS is local only.
- **Internal:** `http://192.168.0.158:30041` (Immich), `:8334` (Syncthing), `:30109` (n8n), `:81` (TrueNAS, local only)

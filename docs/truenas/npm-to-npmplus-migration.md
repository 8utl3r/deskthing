# NPM → NPMplus Migration

Migrate from Nginx Proxy Manager (NPM) to NPMplus on TrueNAS, keeping all proxy hosts, SSL certs, and settings.

## Summary

- **NPM** data lives at `/mnt/.ix-apps/app_mounts/nginx-proxy-manager/` (data + certs).
- **NPMplus** is a fork that uses the same SQLite/`/data` layout and can import certs from NPM’s `/etc/letsencrypt` once, then stores everything under `/data`.
- You can **install NPMplus** (TrueNAS App or manual container), then **copy NPM’s config** into it and run a one-time cert migration.

## Prerequisites

- NPM currently stopped (so files aren’t in use).
- NPMplus installed and configured to use ports **80, 443** (proxy) and **30020** (admin UI) so DNS/UniFi don’t need changes. If you install via TrueNAS Apps, set port overrides in the app’s configuration to match.

## Install only (no migration)

To get NPMplus running first with a fresh config, then migrate later:

```bash
/Users/pete/dotfiles/scripts/truenas/npmplus-install.sh
```

This stops NPM, creates `/mnt/.ix-apps/app_mounts/npmplus/data`, and starts NPMplus. Admin UI: **http://192.168.0.158:30020**. First login: `admin@example.org`; the password is in the container logs on first start. After that you can run the migration steps to copy NPM data and certs in.

## Option A: TrueNAS App “Nginx Proxy Manager Plus”

**Port strategy:** Install with **default ports** (WebUI 30360, HTTP 30361, HTTPS 30362) so NPMplus does not conflict with existing NPM (30020, 80, 443). After you uninstall the old NPM, edit NPMplus and set WebUI → 30020, HTTP → 80, HTTPS → 443.

1. In **Apps**, install **Nginx Proxy Manager Plus** (confirm image is `zoeyvid/npmplus`). Leave default ports during install.
2. Start the app. Admin UI is at **http://192.168.0.158:30360** for now.
3. When ready to migrate, run (from your Mac):
   ```bash
   /Users/pete/dotfiles/scripts/truenas/npmplus-migrate-from-npm.sh
   ```
   The script finds the NPMplus app’s data path, stops the old NPM, copies its database and certs into NPMplus, and restarts the app. Log in with your **previous NPM** admin email and password.
4. **Remove old NPM and set NPM+ ports** (from your Mac):
   ```bash
   /Users/pete/dotfiles/scripts/truenas/npmplus-remove-npm-and-set-ports.sh
   ```
   This uninstalls the old NPM app (if present), sets NPM+ to Web UI **30020**, HTTP **80**, HTTPS **443**, and restarts NPM+. Admin: **https://192.168.0.158:30020**, proxy on 80/443.  
   **Manual fallback:** Apps → Installed → nginx-proxy-manager → Uninstall; then npmplus → Edit → Network → set ports → Save → Restart.

## Option B: Manual container (like current NPM)

**One-time migration and first start** (from your Mac):

```bash
/Users/pete/dotfiles/scripts/truenas/npmplus-migrate-and-start.sh
```

This stops NPM, copies its data into `/mnt/.ix-apps/app_mounts/npmplus/data`, and starts NPMplus with NPM’s certs mounted at `/etc/letsencrypt` so certs are migrated into `/data`. Requires `factorio/.env.nas` with `NAS_SUDO_PASSWORD`.

**After the first run** (once certs are in `/data`), stop the container and start without the cert mount:

```bash
/Users/pete/dotfiles/scripts/truenas/npmplus-start.sh
```

Use `npmplus-start.sh` whenever you need to start NPMplus (e.g. after a reboot). Same ports as before: 80, 443, 30020.

## Copy steps

Run on the NAS (SSH `truenas_admin@192.168.0.158`). Replace `TARGET_DATA` with the NPMplus `/data` directory (e.g. `/mnt/.ix-apps/app_mounts/nginx-proxy-manager-plus/data` or `/mnt/.ix-apps/app_mounts/npmplus/data`).

```bash
# 1. Stop NPM so files are not in use
# (From Apps UI or: sudo docker stop ix-nginx-proxy-manager-npm-1)

# 2. Set target (NPMplus data directory on host)
TARGET_DATA="/mnt/.ix-apps/app_mounts/npmplus/data"   # or your Plus app path

# 3. Create target and copy NPM data (proxy hosts, DB, nginx config)
sudo mkdir -p "$TARGET_DATA"
sudo rsync -a /mnt/.ix-apps/app_mounts/nginx-proxy-manager/data/ "$TARGET_DATA/"

# 4. Certs: NPMplus will read from /etc/letsencrypt on first start and move them into /data.
#    So either:
#    - Mount NPM's certs as /etc/letsencrypt on first start (recommended), or
#    - Copy into NPMplus certbot dir (if you know the structure):
#      sudo mkdir -p "$TARGET_DATA/tls/certbot"
#      sudo rsync -a /mnt/.ix-apps/app_mounts/nginx-proxy-manager/certs/ "$TARGET_DATA/tls/certbot/"
```

Or use the script from this repo (run from your Mac, or copy script to NAS and run there):

```bash
./scripts/truenas/npm-to-npmplus-copy.sh [target_data_path]
```

See `scripts/truenas/npm-to-npmplus-copy.sh` for details.

## After migration

- **Admin UI:** `http://192.168.0.158:30020` (same as before).
- **Proxy:** Ports 80/443 unchanged; no DNS or UniFi changes needed.
- You can remove or leave the old NPM app stopped; keep a backup of `/mnt/.ix-apps/app_mounts/nginx-proxy-manager/` until you’re satisfied.
- NPMplus features you gain: HTTP/3, CrowdSec option, dark mode, performance tweaks (see `docs/truenas/npm-vs-npmplus-feature-matrix.md`).

## References

- NPMplus compose and migration note: [ZoeyVid/NPMplus compose.yaml](https://github.com/ZoeyVid/NPMplus/blob/develop/compose.yaml) (volume `/path/to/old/npm/letsencrypt/folder:/etc/letsencrypt` for initial migration).
- Feature comparison: `docs/truenas/npm-vs-npmplus-feature-matrix.md`.
- NPM recovery: `docs/truenas/npm-manual-container-recovery.md`.

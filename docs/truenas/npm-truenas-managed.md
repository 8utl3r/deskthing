# Nginx Proxy Manager as a TrueNAS-Managed App

If you want **updates via the TrueNAS UI/API**, the app must come from the TrueNAS catalog. The catalog has **Nginx Proxy Manager** (original, jc21 image), not **NPMplus**.

- **TrueNAS-managed (updates in UI):** Install the catalog app **Nginx Proxy Manager**. You get start/stop, updates, and lifecycle in Apps.
- **NPMplus:** Not in the catalog. Use the manual container scripts (`npmplus-install.sh`, `npmplus-start.sh`); updates are manual (pull new image and restart).

## Install Nginx Proxy Manager (catalog) via UI

1. **Apps** → **Discover** → search **nginx-proxy-manager** → **Install**.
2. In the install wizard:
   - **Network:** WebUI Port **30020**, HTTP Port **80**, HTTPS Port **443**.
   - **Storage:** Use **ixVolume** (default) or **Host Path** (e.g. `/mnt/tank/apps/nginx-proxy-manager` or existing `/mnt/.ix-apps/app_mounts/...`).
3. **Save** and start the app. Admin UI: **http://192.168.0.158:30020**.

After that, **Apps** → **Installed** → **nginx-proxy-manager** shows the app and you can use **Upgrade** when the catalog has a new version.

## Install via SSH/API (script)

From your Mac (requires `factorio/.env.nas` with `NAS_SUDO_PASSWORD`):

```bash
/Users/pete/dotfiles/scripts/truenas/npm-install-catalog-app.sh
```

The script SSHs to the NAS and tries to install the **nginx-proxy-manager** app from the Community catalog via the TrueNAS API. If the API shape differs on your version, it prints the UI steps above.

## If you need NPMplus

Use the manual container and accept manual updates:

- Install: `scripts/truenas/npmplus-install.sh`
- Start (after reboot): `scripts/truenas/npmplus-start.sh`
- Update: change script to a newer `zoeyvid/npmplus` tag and re-run, or `docker pull zoeyvid/npmplus:latest` on the NAS and restart the container.

See **docs/truenas/npm-to-npmplus-migration.md** for migrating from NPM to NPMplus.

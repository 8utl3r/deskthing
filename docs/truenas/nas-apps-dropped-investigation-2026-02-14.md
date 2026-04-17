# NAS Apps Dropped — Investigation (2026-02-14)

## Summary

**What happened:** TrueNAS showed zero installed apps; Docker was inactive; UI reported "Unable to determine default interface" when configuring Apps.

**Resolution:** A **reboot** brought everything back. All apps are functioning again. The issue was likely transient (Docker/Apps or interface detection in a bad state).

**If it happens again:** Try **reboot first**. If that doesn't fix it, see [If reboot doesn't help](#if-reboot-doesnt-help) below.

---

## Error message (2026-02-14)

When trying to configure Apps (e.g. selecting pool in Apps → Settings), the UI may show:

```text
Failed to configure docker for Applications: Unable to determine default interface
2026-02-14 07:42:59 (America/Chicago)
```

That means TrueNAS's Apps/Docker setup could not automatically pick the default network interface. If reboot didn't fix it, set **Apps → Settings → Advanced Settings → IPv4 Interface** to **enp2s0**, then Save.

---

## If reboot doesn't help

Only if a reboot didn't restore apps:

1. **Apps → Settings → Advanced Settings** — set **IPv4 Interface** to **enp2s0**, Save.
2. **Apps → Settings** — set **Pool** to **tank**, Save; wait for Docker to start.
3. If the app list is still empty (metadata lost), reinstall apps from **Apps → Discover** and point each app's storage at the same host paths you used before (e.g. `/mnt/tank/apps/immich`, `/mnt/tank/apps/n8n`). See `nas-apps-health.txt` for your app list.

---

## What we saw (before reboot)

The evidence below was collected while apps appeared "dropped." After reboot, apps and Docker came back without needing interface/pool changes or reinstalls — so the state was likely transient.

| Check | Result |
|-------|--------|
| `midclt call app.query` | `[]` (no apps) |
| `midclt call docker.config` | `dataset: "tank/ix-apps"`, `pool: "tank"` |
| `midclt call pool.dataset.query` for `tank/ix-apps` | `[]` (dataset does not exist) |
| Pool `tank` datasets | `tank`, `tank/media`, `tank/apps`, `tank/apps/rules_server`, `tank/backups`, `tank/documents` — **no** `tank/ix-apps` |
| `systemctl is-active docker` | `inactive` |
| `/mnt/.ix-apps` (boot-pool) | Exists but empty (no `app_configs`, no `app_mounts`) |
| Pool `tank` status | ONLINE, healthy (mirror, resilver finished) |
| `/mnt/tank/apps` | Present, ~31 GB used (your app **data** is still there) |

---

## References

- `docs/truenas/nas-apps-health.txt` — last known app list (2026-02-09)
- `docs/truenas/nas-outage-analysis-2026-01-24.md` — Jan 2026 disk I/O outage
- `docs/truenas/truenas-app-service-urls.md` — ports and hostnames
- TrueNAS 25.04.2.6, pool `tank` (mirror)

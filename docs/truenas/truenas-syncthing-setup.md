# Syncthing Setup on TrueNAS Scale

## Overview

Syncthing provides simple, decentralized file sync. Works great with ZFS snapshots for versioning/backups.

## Prerequisites

✅ Storage directory created:
- `/mnt/tank/apps/syncthing` - Syncthing config/data

✅ Permissions set:
- `apps:apps` (568:568)

## Installation

### Step 1: Remove Seafile (If Installed)

1. **Apps → Installed Apps → seafile**
2. **Stop** the app
3. **Delete** the app (optional - removes containers)
4. **Delete data** (if you want clean slate):
   ```bash
   rm -rf /mnt/tank/apps/seafile-data/*
   rm -rf /mnt/tank/apps/seafile/db/*
   ```

### Step 2: Install Syncthing

**Option A: TrueCharts Catalog (Recommended)**

1. **Add TrueCharts Catalog:**
   - Apps → Settings → Manage Catalogs
   - Add: `https://charts.truecharts.org`
   - Train: `enterprise` or `stable`

2. **Install Syncthing:**
   - Apps → Discover Apps
   - Search: `syncthing`
   - Install from TrueCharts catalog

3. **Configure:**
   - **Storage:** `/mnt/tank/apps/syncthing`
   - **Port:** 8384 (web UI)
   - **Port:** 22000 (sync protocol)

**Option B: Custom App (If Catalog Doesn't Work)**

1. **Apps → Discover Apps → Install via YAML**

2. **Use this YAML:**
```yaml
version: '3.8'

services:
  syncthing:
    image: syncthing/syncthing:latest
    container_name: syncthing
    ports:
      - "8384:8384"  # Web UI
      - "22000:22000/tcp"  # Sync protocol
      - "22000:22000/udp"  # Sync discovery
    volumes:
      - /mnt/tank/apps/syncthing:/var/syncthing
    restart: unless-stopped
    environment:
      - PUID=568
      - PGID=568
```

### Step 3: Access Web UI

- **URL:** `http://192.168.0.158:8384`
- **First time:** Set admin password
- **Add devices:** Scan QR code or enter device ID

### Step 4: Configure Folders

1. **Add folder** in Syncthing web UI
2. **Path:** `/var/syncthing/YourFolderName`
3. **Share** with your devices
4. **Files sync** automatically

## ZFS Snapshots for Versioning

TrueNAS automatically creates snapshots. Configure in:
- **Storage → Periodic Snapshot Tasks**
- **Frequency:** Hourly/Daily
- **Retention:** Keep 24 hourly, 7 daily, etc.

## Qdrant Integration

Syncthing stores **real files** (not blocks), so indexing is easy:

1. **Point Qdrant** at Syncthing folder: `/mnt/tank/apps/syncthing/YourFolderName`
2. **Index files** normally
3. **Auto-update** as files sync

## Advantages Over Seafile

- ✅ **Simple setup** - no database, no complex config
- ✅ **Lightweight** - ~100-200MB RAM
- ✅ **Real files** - easy Qdrant indexing
- ✅ **Decentralized** - no single point of failure
- ✅ **Works on current hardware** - no RAM upgrade needed

## Upgrading Syncthing (host path validation error)

If the upgrade fails with:

```text
ValidationErrors: [EINVAL] app_create.storage.config.host_path_config.acl: /mnt/tank/apps/syncthing: path contains existing data and `force` was not specified
```

TrueNAS is blocking the upgrade because the host path already has data (your existing Syncthing config). Two options:

**Option 1: Temporarily disable host path safety checks (quickest)**

From your Mac (requires `factorio/.env.nas` with `NAS_SUDO_PASSWORD`):

```bash
./scripts/truenas/syncthing-upgrade-fix.sh
```

The script SSHs to the NAS, tries to disable the check via the API, triggers the upgrade, then re-enables the check. If your TrueNAS version doesn’t expose the setting via API, it will print the manual UI steps.

Manual UI steps:

1. **Apps → Settings → Advanced Settings**
2. Turn **off** **Enable Host Path Safety Checks**
3. Run the Syncthing **Upgrade** again
4. Turn **Enable Host Path Safety Checks** back **on** if you want the protection for other apps

**Option 2: Per-volume “force” (if your version has it)**

1. **Apps → Installed → Syncthing → Edit** (or **Upgrade** screen)
2. Open the **Storage** section and find the volume that uses `/mnt/tank/apps/syncthing`
3. Look for **Allow existing data**, **Force use of path**, or similar and enable it
4. Save and run the upgrade

Option 1 is safe for this case: the path is used only by Syncthing, not by SMB/NFS shares, so the safety check is being overly cautious.

## Troubleshooting

**Can't access web UI:**
- Check port 8384 is open
- Verify container is running

**Files not syncing:**
- Check devices are connected (green in web UI)
- Verify folder is shared with device
- Check firewall allows port 22000

**Permission errors:**
- Ensure `/mnt/tank/apps/syncthing` owned by `apps:apps`
- Check PUID/PGID match (568:568)

# Jellyfin Installation on TrueNAS Scale

> **Note:** The Servarr stack runs Jellyfin on the **Pi**, not the NAS. Use this guide only if you want Jellyfin on the NAS instead. For Pi: see `docs/services/jellyfin-pi5-docker-setup.md`.

## Strategy: Use 10.10.7 (Avoids 10.11 Migration Bugs)

Jellyfin 10.11 has fresh-install migration bugs (`__EFMigrationsHistory`, `TypedBaseItems`). The TrueNAS catalog offers **10.10.7**, which works reliably.

## Option 1: Install from Catalog (Recommended)

1. **Apps** → **Discover Apps**
2. In the **Search** field, type `Jellyfin`
3. Click the **Jellyfin** app widget
4. Click **Install**
5. Configure:

### Storage (Required)

- **Jellyfin Config:** Host Path `/mnt/tank/apps/jellyfin/config` (or ixVolume)
- **Jellyfin Cache:** Host Path `/mnt/tank/apps/jellyfin/cache` (or ixVolume)
- **Jellyfin Transcodes:** Host Path `/mnt/tank/apps/jellyfin/transcodes` or **emptyDir**

### Additional Storage (Media Libraries)

Click **Add** for each library:

| Mount Path (in container) | Host Path (TrueNAS) | Purpose |
|---------------------------|---------------------|---------|
| `/media/movies`           | `/mnt/tank/media/movies` | Movies |
| `/media/tv`               | `/mnt/tank/media/tv`     | TV Shows |
| `/media/music`            | `/mnt/tank/media/music` | Music |
| `/media/books`            | `/mnt/tank/media/books` | Books |

Adjust paths if your media is elsewhere (e.g. `/mnt/tank/video/movies`).

### Network

- **Host Network:** Enable if using DLNA
- **Web Port:** Default 30013 (or 8096 if you prefer)

### Deploy

Click **Install**. When status is **Running**, click **Web Portal** to open the Jellyfin setup wizard.

---

## Option 2: Custom App (Pin to 10.10.7)

If the catalog version differs, use **Custom App** with this YAML:

1. **Apps** → **Discover Apps** → **Custom App** (or ⋮ → **Install via YAML**)
2. Paste:

```yaml
version: "3.8"

services:
  jellyfin:
    image: jellyfin/jellyfin:10.10.7
    container_name: jellyfin
    restart: unless-stopped
    ports:
      - "8096:8096"
    environment:
      - TZ=America/Los_Angeles
      - PUID=568
      - PGID=568
    volumes:
      - /mnt/tank/apps/jellyfin/config:/config
      - /mnt/tank/apps/jellyfin/cache:/cache
      - /mnt/tank/apps/jellyfin/transcodes:/config/transcodes
      - /mnt/tank/media/movies:/media/movies:ro
      - /mnt/tank/media/tv:/media/tv:ro
      - /mnt/tank/media/music:/media/music:ro
      - /mnt/tank/media/books:/media/books:ro
```

3. Map volumes in the wizard:
   - Config: `/mnt/tank/apps/jellyfin/config` → `/config`
   - Cache: `/mnt/tank/apps/jellyfin/cache` → `/cache`
   - Transcodes: `/mnt/tank/apps/jellyfin/transcodes` → `/config/transcodes`
   - Media paths as above
4. **Deploy**

---

## Pre-create Directories (Optional)

```bash
# On TrueNAS Shell (System Settings → Shell)
mkdir -p /mnt/tank/apps/jellyfin/{config,cache,transcodes}
mkdir -p /mnt/tank/media/{movies,tv,music,books}
chown -R 568:568 /mnt/tank/apps/jellyfin
```

---

## Post-Install

1. Open Jellyfin Web Portal
2. Create admin user (e.g. `admin` / `12345678`)
3. Add libraries: Movies, TV Shows, Music, Books (paths: `/media/movies`, etc.)
4. Complete wizard

---

## Upgrade to 10.11 Later

Once 10.10.7 is running with data, you can upgrade to 10.11 via the app update in TrueNAS. The migration from 10.10 → 10.11 is supported; fresh 10.11 installs have the bugs.

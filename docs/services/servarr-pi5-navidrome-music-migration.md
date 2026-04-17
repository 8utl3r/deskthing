# Servarr Pi 5: Switch Music from Jellyfin to Navidrome

**Purpose:** Replace Jellyfin Music with Navidrome for a better music experience. Jellyfin keeps Movies + TV only.

**Date:** 2026-02-08

---

## Current Setup (Music Path)

| Component | Role | Path / Port |
|-----------|------|-------------|
| **Lidarr** | Music automation | Root folder: `/mnt/data/media/music` |
| **jellyfin-autoscan** | Triggers Jellyfin scan | Webhook from Lidarr → `http://localhost:8282/refresh` |
| **Jellyfin** | Music library | `/media/music` (→ `/mnt/data/media/music`) |
| **listen.xcvr.link** | Audio subdomain | Caddy → Jellyfin (Caddy not installed yet; jellyfin.xcvr.link via NPM) |

---

## Target Setup

| Content | Service | Port | URL |
|---------|---------|------|-----|
| Movies & TV | Jellyfin | 8096 | jellyfin.xcvr.link |
| Music | Navidrome | 4533 | music.xcvr.link or listen.xcvr.link |
| Audiobooks | Audiobookshelf | 13378 | (future) |
| Ebooks | Audiobookshelf | 13378 | (future) |

---

## Migration Steps

### 1. Deploy Navidrome on Pi 5

**Option A: Docker run (Pi has no docker-compose)**

```bash
# On Pi (ssh pi@192.168.0.136)
sudo mkdir -p /var/lib/navidrome
sudo chown -R 1000:1000 /var/lib/navidrome

sudo docker run -d \
  --name navidrome \
  --restart unless-stopped \
  -p 4533:4533 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/Los_Angeles \
  -e ND_SCANINTERVAL=1m \
  -v /var/lib/navidrome:/data \
  -v /mnt/data/media/music:/music:ro \
  deluan/navidrome:latest
```

**Option B: Script** (create `scripts/servarr-pi5-navidrome-setup.sh`)

---

### 2. Initial Navidrome Setup

1. Open http://pi5.xcvr.link:4533 (or http://192.168.0.136:4533)
2. Create admin user (e.g. pete / password)
3. Add subusers if needed (Settings → Users)
4. Navidrome auto-scans on startup. With `ND_SCANINTERVAL=1m`, it rescans every minute. Lidarr imports will appear within ~1–2 minutes.

---

### 3. Remove Music from Jellyfin

1. Jellyfin Dashboard → Libraries
2. Delete the **Music** library
3. (Optional) Remove the `/media/music` mount from the Jellyfin container if redeploying—or leave it; it won't show without a library.

**Or via API** (if you have JELLYFIN_API_KEY):

```bash
# Get library IDs
curl -s "http://192.168.0.136:8096/Library/VirtualFolders" \
  -H "X-Emby-Token: $JELLYFIN_API_KEY" | python3 -m json.tool

# Delete Music library (replace LIBRARY_ID with the Music library's Id)
curl -X DELETE "http://192.168.0.136:8096/Library/VirtualFolders/LIBRARY_ID" \
  -H "X-Emby-Token: $JELLYFIN_API_KEY"
```

---

### 4. Lidarr → No Change

- Lidarr keeps writing to `/mnt/data/media/music`
- No need to add Navidrome webhook: Navidrome scans every 1 minute via `ND_SCANINTERVAL`
- jellyfin-autoscan webhook can stay; it will still trigger Jellyfin refresh (harmless; Music library is gone)

**Optional:** Remove Lidarr's Jellyfin-Autoscan webhook if you want to avoid unnecessary Jellyfin scans. Sonarr/Radarr still need it.

---

### 5. Reverse Proxy (Caddy or NPM)

**If using Caddy** (listen.xcvr.link):

```caddyfile
# listen.xcvr.link → Navidrome (music)
listen.xcvr.link {
	reverse_proxy localhost:4533
}

# watch.xcvr.link → Jellyfin (movies, TV)
watch.xcvr.link {
	reverse_proxy localhost:8096
}
```

**If using NPM** (jellyfin.xcvr.link already exists):

- Add **music.xcvr.link** or **listen.xcvr.link** → Proxy to `192.168.0.136:4533`
- Optionally point listen.xcvr.link to Navidrome instead of Jellyfin

---

### 6. Mobile Clients

| Platform | App | Notes |
|----------|-----|------|
| **Android** | Symfonium | Paid; supports Navidrome, offline, Android Auto |
| **Android** | Musly | Free; modern UI |
| **iOS** | Amperfy | Subsonic client; offline, CarPlay |

Add server: `http://music.xcvr.link` (or `http://pi5.xcvr.link:4533`). Use Subsonic API; Navidrome is compatible.

---

## Navidrome Config Options

| Variable | Default | Notes |
|----------|---------|-------|
| `ND_SCANINTERVAL` | 1m | How often to rescan. `0` disables auto-scan. |
| `ND_LOGLEVEL` | info | debug, info, warn, error |
| `ND_SESSIONTIMEOUT` | 24h | Auth token validity |

---

## Lidarr Music Folder Structure

Lidarr uses: `Artist/Album/Track.mp3`. Navidrome is tag-based and handles this structure. No changes needed.

---

## Rollback

If you want Music back in Jellyfin:

1. Stop Navidrome: `sudo docker stop navidrome`
2. Re-add Music library in Jellyfin (Dashboard → Libraries → Add → Music → `/media/music`)
3. Trigger scan or wait for jellyfin-autoscan (Lidarr webhook)

---

## Files to Create/Update

| File | Action |
|------|--------|
| `scripts/servarr-pi5-navidrome-setup.sh` | Create—Docker run for Navidrome |
| `scripts/servarr-pi5-phase4-jellyfin-config.sh` | Update—remove Music from library list |
| `docs/services/servarr-pi5-architecture.md` | Update—add Navidrome to diagram |
| `docs/services/servarr-pi5-post-install-status.md` | Update—add Navidrome to status |

---

## Summary

1. Deploy Navidrome (Docker, port 4533, mount `/mnt/data/media/music`)
2. Create admin user in Navidrome
3. Remove Music library from Jellyfin
4. Add music.xcvr.link (or listen.xcvr.link) proxy → Navidrome
5. Install Symfonium/Musly/Amperfy on phone, connect to Navidrome

Lidarr flow unchanged. Navidrome picks up new music via 1-minute scan interval.

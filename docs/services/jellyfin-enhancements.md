# Jellyfin Enhancements

**Date:** 2026-02-03

## Installed via script

Run: `./scripts/servarr/jellyfin-enhancements-setup.sh`

### Plugins (auto-installed)

| Plugin | Purpose |
|--------|---------|
| **Trakt** | Sync watch history, ratings, lists with Trakt.tv |
| **Reports** | Library stats, watched, missing items, export to CSV/Excel |
| **TMDb Box Sets** | Auto-collections (MCU, Star Wars, etc.) from TMDb |
| **TheTVDB** | TV metadata (series, seasons, episodes) |
| **Fanart** | Poster/backdrop images from Fanart.tv |

### Intro Skipper (manual)

1. Dashboard → Plugins → Repositories → Add
2. URL: `https://intro-skipper.org/manifest.json`
3. Install "Intro Skipper" from the Intro-Skipper section
4. Restart Jellyfin
5. Dashboard → Scheduled Tasks → Run "Intro Skipper analysis"

### TMDB / TVDB

Enabled by default for Movies/TV. Verify: Dashboard → Libraries → [library] → Manage → Metadata fetchers.

### Collections

TMDb Box Sets plugin creates collections automatically. Refresh: Dashboard → Plugins → TMDb Box Sets → Refresh, or runs daily via scheduled task.

### Artwork

Dashboard → Libraries → [library] → Manage → Image fetchers. Add Fanart, reorder (TMDB first, then Fanart, etc.).

### Direct Play & quality

- **Direct Play:** Default; preferred on Pi 5 (no hardware encoders).
- **Per-user bitrate:** Dashboard → Users → [user] → Playback → Internet streaming bitrate limit (e.g. 8 Mbps for remote).

### Scheduled scans

Default: Scan Media Library every 12 hours. Dashboard → Scheduled Tasks to adjust.

### Backup

Script: `/usr/local/bin/jellyfin-backup.sh`  
Backs up `/var/lib/jellyfin-docker/config` to `/mnt/data/backups/jellyfin/` (keeps 7 days).

Add to cron: `0 3 * * * /usr/local/bin/jellyfin-backup.sh`

### Reverse proxy

jellyfin.xcvr.link → 192.168.0.136:8096 (NPM). Re-add: `./scripts/npm/npm-api.sh add-jellyfin`

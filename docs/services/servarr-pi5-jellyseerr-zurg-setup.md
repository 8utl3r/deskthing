# Servarr Pi 5: Jellyseerr + Zurg + JellySkin

**Date:** 2026-02-03

## Overview

- **Jellyseerr:** Media request UI; users request movies/TV via Jellyfin sign-in; creates Radarr/Sonarr jobs
- **Zurg:** Real-Debrid WebDAV bridge; exposes RD cached content as a filesystem
- **rclone:** Mounts Zurg WebDAV to `/mnt/zurg` on the Pi
- **JellySkin:** Modern Jellyfin CSS theme (manual paste)

## URLs

| Service | URL |
|---------|-----|
| Jellyseerr | http://pi5.xcvr.link:5055 |
| Zurg WebDAV | http://pi5.xcvr.link:9999/dav |
| Jellyfin | http://pi5.xcvr.link:8096 |

## Jellyseerr Setup

**Fix all connections (Jellyfin + Radarr + Sonarr):**
```bash
./scripts/servarr/jellyseerr-fix-connections.sh
```
Requires `JELLYFIN_API_KEY` in `scripts/servarr/.env`. Configures Jellyfin (host.docker.internal:8096), Radarr (7878), Sonarr (8989).

**Radarr/Sonarr only:** `./scripts/servarr/jellyseerr-configure-radarr-sonarr.sh`

**Manual:** If you prefer to configure in the UI:
1. Open http://pi5.xcvr.link:5055
2. Sign in with Jellyfin (same server)
3. Settings → Radarr: add **hostname** `host.docker.internal`, **port** `7878`, API key from Radarr
4. Settings → Sonarr: add **hostname** `host.docker.internal`, **port** `8989`, API key from Sonarr
5. Users can request media; Jellyseerr creates Radarr/Sonarr jobs

**Important:** Jellyseerr runs in Docker. Use `host.docker.internal` (not localhost) so it can reach Radarr/Sonarr on the host.

## Zurg + rclone (Already Deployed)

- **Zurg:** Docker `zurg` on port 9999; config at `/mnt/data/appdata/zurg/config.yml`
- **rclone:** Docker `rclone-zurg`; mounts Zurg to `/mnt/zurg` (movies, shows, anime); VFS cache at `/mnt/data/appdata/rclone-cache`; 10s startup delay after Zurg
- **Jellyfin:** Has `/mnt/zurg` → `/media/realdebrid`; libraries "Real-Debrid Movies" and "Real-Debrid TV"
- **jellyfin-autoscan:** Zurg's `on_library_update` triggers refresh at `host.docker.internal:8282`
- **Mount order:** Start Zurg + rclone before Jellyfin (or restart Jellyfin after they're up). Otherwise Jellyfin sees an empty /media/realdebrid.

## JellySkin (Manual)

1. Jellyfin Dashboard → General → Custom CSS
2. Paste and Save:

```css
@import url("https://cdn.jsdelivr.net/npm/jellyskin@latest/dist/main.css");
@import url("https://cdn.jsdelivr.net/npm/jellyskin@latest/dist/logo.css");
@import url("https://cdn.jsdelivr.net/npm/jellyskin@latest/dist/addons/gradients/nightSky.css");
```

Optional addons: `sea.css`, `mauve.css` for other gradients.

## Re-run Setup

From Mac: `./scripts/servarr/servarr-pi5-jellyseerr-zurg-setup.sh`

Requires `scripts/servarr/.env` with `JELLYFIN_API_KEY` and `REAL_DEBRID_API_KEY`.

## Troubleshooting

See **`docs/services/servarr-pi5-zurg-troubleshooting.md`** for detailed fixes from successful setups (Unraid, Pi 5, rclone forum).

**Empty libraries (TV Shows, Movies, Real-Debrid all show 0 items)**
- Cause: "Transport endpoint is not connected" on the rclone mount—Jellyfin cached a stale reference.
- Fix: `./scripts/servarr/jellyfin-mount-fix.sh` — restarts rclone then Jellyfin so Jellyfin sees the fresh mount.
- Startup order: Start Zurg + rclone before Jellyfin (or restart Jellyfin after they're up).

**Video freezes on seek/skip, audio continues**
- Jellyfin transcoding bug. Run `./scripts/servarr/jellyfin-force-direct-play.sh` to disable transcoding, or do it manually in Dashboard → Users → Playback. See troubleshooting doc §7.

**Playback error: "Playback failed due to a fatal player error"**
- Run: `./scripts/servarr/zurg-rclone-playback-fix.sh` for improved rclone mount options (vfs-read-ahead, buffer-size)
- **Verify:** Assume playback fails until verified. Run `./scripts/servarr/jellyfin-playback-verify.sh`
- If one file fails but others work: that torrent may be expired on Real-Debrid—remove it from RD and re-add
- Prefer 1080p or direct-play when possible; 4K HEVC transcoding is heavy on Pi 5

**Duplicate movies in Real-Debrid library**
- Run `./scripts/servarr/rd-dedupe-torrents.sh --dry-run` to preview, then without `--dry-run` to delete. Or clean up manually in RD web UI: My Downloads.

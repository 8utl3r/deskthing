# Servarr Pi 5: Post-Install Status

**Date:** 2026-02-02  
**Host:** servarr (Pi 5, NVMe boot)  
**IP:** 192.168.0.136 (static)  
**DNS:** pi5.xcvr.link (local)

---

## PiJARR Services (All Running)

| Service | Port | Status |
|---------|------|--------|
| Jackett | 9117 | active |
| Sonarr | 8989 | active |
| Radarr | 7878 | active |
| Lidarr | 8686 | active |
| LazyLibrarian | 5299 | active |
| Prowlarr | 9696 | active |
| Bazarr | 6767 | active |
| FlareSolverr | 8191 | active |
| qBittorrent-nox | 8080 | active |

---

## Fixes Applied (FlareSolverr + qBittorrent)

PiJARR's interactive install timed out before completing FlareSolverr and qBittorrent. These were fixed manually:

1. **FlareSolverr**
   - Installed Python deps: `sudo /opt/Flaresolverr/venv/bin/pip install -r /opt/Flaresolverr/requirements.txt`
   - Installed Chromium + Xvfb: `sudo apt install -y chromium xvfb`
   - Created systemd service at `/etc/systemd/system/flaresolverr.service` (ExecStart: venv python + flaresolverr.py)

2. **qBittorrent-nox**
   - Installed: `sudo apt install -y qbittorrent-nox`
   - Created systemd service with `--confirm-legal-notice` flag

---

## SSH Access

```bash
ssh pi@pi5.xcvr.link
# or: ssh pi@192.168.0.136
```

**If SSH fails (password/key not set up):** Use KVM console to add your Mac's key:

1. On Mac: `./scripts/servarr-pi5-ssh-setup-via-kvm.sh`
2. Switch KVM to Pi 5 (Jet KVM web UI: http://192.168.0.197), log in as `pi`
3. Paste the output line into the Pi console, press Enter
4. Test: `ssh pi@192.168.0.136`

---

## Phase 3 Complete (2026-02-02)

- **FlareSolverr proxy:** Added to Prowlarr (for Cloudflare indexers)
- **1337x indexer:** Blocked by Cloudflare during add; add manually in Prowlarr UI (Indexers → Add → 1337x, assign FlareSolverr proxy)
- **Prowlarr → *arr:** Sonarr, Radarr, Lidarr added as apps; indexers will sync. LazyLibrarian adds Prowlarr as Newznab manually.
- **qBittorrent:** Added as download client to all four *arr apps (admin/adminadmin)
- **Root folders:** /mnt/data/media/{tv,movies,music} set in Sonarr, Radarr, Lidarr; LazyLibrarian uses books/ and audiobooks/
- **Permissions:** /mnt/data chown pi:media, chmod g+rwX for *arr access

**qBittorrent setup:** Set default save path to `/mnt/data/torrents` in Web UI (Tools → Options → Downloads). If admin/adminadmin fails, get temp password from `sudo journalctl -u qbittorrent-nox -n 5`, log in, set password in Options → Web UI.

**Access URLs (local):** http://pi5.xcvr.link:9696 (Prowlarr), http://pi5.xcvr.link:8080 (qBittorrent), etc.

## Phase 4: Jellyfin (2026-02-02) ✅

- **Running:** Docker jellyfin/jellyfin:10.10.7 on port 8096
- **URL:** http://pi5.xcvr.link:8096 (or 192.168.0.136:8096)
- **Post-install:** Open URL → wizard → create admin (e.g. admin/12345678) → add libraries (Movies `/media/movies`, TV `/media/tv`, etc.).
- **Add test user:** After wizard, run `JF_PASS=your_admin_password JF_BASE=http://pi5.xcvr.link:8096 ./scripts/servarr-pi5-jellyfin-add-test-user.sh` (creates test/test1234).
- **Hardware acceleration:** Pi 5 has no hardware encoders; use Direct Play where possible; transcoding falls back to CPU.

## Phase 5: Jellyseerr + Zurg + JellySkin (2026-02-03) ✅

- **Jellyseerr:** http://pi5.xcvr.link:5055 — Radarr + Sonarr pre-configured via `./scripts/servarr/jellyseerr-configure-radarr-sonarr.sh` (host.docker.internal)
- **Zurg:** Real-Debrid WebDAV at http://pi5.xcvr.link:9999/dav; rclone mount at `/mnt/zurg` (movies, shows, anime)
- **Jellyfin Real-Debrid libraries:** "Real-Debrid Movies" and "Real-Debrid TV" added; content streams from RD cache
- **JellySkin theme:** Manual step — Dashboard → General → Custom CSS, paste:
  ```
  @import url("https://cdn.jsdelivr.net/npm/jellyskin@latest/dist/main.css");
  @import url("https://cdn.jsdelivr.net/npm/jellyskin@latest/dist/logo.css");
  @import url("https://cdn.jsdelivr.net/npm/jellyskin@latest/dist/addons/gradients/nightSky.css");
  ```
- **Setup script:** `./scripts/servarr/servarr-pi5-jellyseerr-zurg-setup.sh` (requires Docker; Pi has no docker-compose, Zurg/rclone use `docker run`)
- **Enhancements:** `./scripts/servarr/jellyfin-enhancements-setup.sh` — Trakt, Reports, TMDb Box Sets, TheTVDB, Fanart, backup script. See `docs/services/jellyfin-enhancements.md`

## Next Steps (Phase 4+)

1. ~~Complete Jellyfin setup wizard~~ ✅ Done (pete / libraries added)
2. ~~Connect Jellyfin to *arr~~ ✅ jellyfin-autoscan deployed — webhooks in Sonarr/Radarr/Lidarr + LazyLibrarian custom script trigger library scans. See `docs/services/servarr-jellyfin-connection.md`
3. **Indexers + Debrid:** ✅ Indexers added (YTS, LimeTorrents, EZTV, Nyaa.si). rdt-client deployed with Real-Debrid, added to Radarr/Sonarr/Lidarr. LazyLibrarian adds rdt-client in its UI. See `docs/services/servarr-pi5-indexers-debrid-setup.md`
4. **Usenet:** ✅ Sabnzbd deployed, categories added, Sabnzbd added to Radarr/Sonarr/Lidarr. LazyLibrarian adds Sabnzbd in its UI. See `docs/services/servarr-pi5-usenet-setup.md`
5. ~~Prowlarr → Settings → Apps → Sync App Indexers~~ ✅ Run `./scripts/servarr-pi5-sync-and-usenet-indexers.sh` (syncs indexers; adds Usenet indexers from .env if keys set)

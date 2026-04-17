# Servarr Pi 5: Zurg + rclone Troubleshooting

**Date:** 2026-02-05  
**Sources:** Unraid Real-Debrid guide, rclone forum, Jellyfin issues, TheRandy Pi 5 success

## Successful Setups Reference

### Unraid (hernandito) – Plex + Zurg + rclone

- **rclone:** Runs on **host** (not Docker). Mount command:
  ```bash
  rclone mount zurg-wd: /mnt/downloadcache/zurg \
    --dir-cache-time 20s \
    --config=/mnt/user/appdata/zurg/rclone.conf \
    --allow-other --allow-non-empty --gid 100 --uid 99 --daemon
  ```
- **Start order:** Zurg first, then rclone (10s sleep between). rclone needs Zurg WebDAV up.
- **Mount location:** Pool/cache, NOT array (FUSE on array can be unreliable).
- **Multiple users:** Nonoss, scott2020, bidalos confirmed success following the guide.

### TheRandy – Pi 5 + Ubuntu

- Worked with godver3 (CLI_Debrid author) to get Zurg + rclone working on **Raspberry Pi 5 running Ubuntu**.
- Later moved to unRAID; had issues with wrong zurg binary (linux-amd64 on ARM → use `linux-arm64` for Pi).

### rclone Forum – Docker + FUSE propagation

- Use `:rshared` on the mount volume so the FUSE mount propagates to the host.
- Required: `--cap-add SYS_ADMIN`, `--security-opt apparmor:unconfined`, `--device /dev/fuse`.
- Stale mounts: run `fusermount -u -z /mnt/zurg` before restarting rclone.

---

## Common Issues and Fixes

### 0. Debrid streams won't play (playback doesn't start or fails immediately)

**Symptoms:** Clicking play on a Real-Debrid (Zurg) title does nothing, shows "fatal player error", or loads then fails. Local library titles may work.

**Try in this order:**

1. **NPM WebSocket (if using jellyfin.xcvr.link)**  
   Jellyfin uses WebSockets for streaming control. If the NPM proxy has WebSocket disabled or buffering on, playback can fail. Run:
   ```bash
   ./scripts/npm/npm-api.sh fix-jellyfin
   ```
   Then try playback again. (Requires `NPM_TOKEN` in `scripts/npm/.env`.)

2. **Verify mount and read**  
   Run the playback verification script (from your Mac):
   ```bash
   ./scripts/servarr/jellyfin-playback-verify.sh
   ```
   If it reports mount empty or file read FAIL, run:
   ```bash
   ./scripts/servarr/jellyfin-mount-fix.sh
   ./scripts/servarr/zurg-rclone-playback-fix.sh
   ```
   Then re-run the verify script.

3. **Force Direct Play (transcoding issues)**  
   If playback starts but freezes on seek, or the client triggers transcoding and fails, disable transcoding:
   ```bash
   ./scripts/servarr/jellyfin-force-direct-play.sh
   ```
   Requires `JELLYFIN_API_KEY` in `scripts/servarr/.env`.

4. **Single title fails, others work**  
   That torrent may be expired on Real-Debrid. Remove it in RD web UI (My Downloads) and re-add or try another title.

**If it still fails:** Note the exact error (Jellyfin web UI message, or Dashboard → Logs). Check whether you're opening Jellyfin via **jellyfin.xcvr.link** (needs step 1) or directly **http://pi5.xcvr.link:8096** (no NPM).

### 1. "Transport endpoint is not connected"

**Cause:** Jellyfin cached a stale reference to the rclone mount; mount went away or restarted.

**Fix:**
```bash
./scripts/servarr/jellyfin-mount-fix.sh
```
This script: (1) optionally cleans stale mount with `fusermount -uz`, (2) restarts rclone, (3) restarts Jellyfin, (4) triggers library scan.

**Prevention:** Start Zurg → rclone → Jellyfin in that order. If rclone restarts, restart Jellyfin so it picks up the fresh mount.

### 2. Playback fails: "Input/output error" or "fatal player error"

**Cause:** rclone FUSE mount needs larger buffers and read-ahead for streaming.

**Fix:**
```bash
./scripts/servarr/zurg-rclone-playback-fix.sh
```

**Verify:** Assume playback is failing until verified. Run:
```bash
./scripts/servarr/jellyfin-playback-verify.sh
```
Adds: `--vfs-read-ahead 512M`, `--buffer-size 256M`, `--vfs-cache-max-size 20G`, `--vfs-read-chunk-size 64M`, and a cache volume.

**If one file fails but others work:** That torrent may be expired on Real-Debrid. Remove it in RD web UI (My Downloads) and re-add.

### 3. Empty libraries after boot

**Cause:** Jellyfin started before rclone mount was ready.

**Fix:** Restart Jellyfin after Zurg and rclone are up:
```bash
ssh pi@pi5.xcvr.link "sudo docker restart jellyfin"
```
Or use `jellyfin-mount-fix.sh` which restarts both rclone and Jellyfin.

**Startup order (recommended):** Zurg → rclone (wait 10s) → Jellyfin.

### 4. Duplicate movies in Real-Debrid library

**Cause:** Real-Debrid caches multiple torrents for the same movie; Zurg exposes each as a separate entry.

**Fix (script):** `./scripts/servarr/rd-dedupe-torrents.sh` — uses Real-Debrid API to find duplicates by title+year, keeps largest file, deletes rest. Use `--dry-run` first.
**Fix (manual):** Real-Debrid web UI: My Downloads → remove duplicate torrents. Or Debrid Media Manager (debridmediamanager.com) with its duplicate filters.

### 5. Duplicate library tiles and Continue Watching

**Cause:** Separate "Movies" and "Real-Debrid Movies" (and TV equivalents) cause the same content to appear twice when it exists in both local storage and RD.

**Fix (programmatic):** `./scripts/servarr/jellyfin-dedupe-libraries.sh` — merges RD paths into Movies/TV Shows, removes standalone RD libraries. Idempotent; safe to run repeatedly.

**Automation:** The script runs automatically after `jellyfin-mount-fix.sh`. For standalone cron (e.g. daily 3am):
```bash
0 3 * * * cd /Users/pete/dotfiles && ./scripts/servarr/jellyfin-dedupe-libraries.sh
```

### 6. rclone "Daemon timed out" or mount fails

**Cause:** Zurg not running, or wrong rclone remote (URL/port).

**Fix:**
- Ensure Zurg is up: `curl -s http://pi5.xcvr.link:9999` (should return zurg status).
- Check rclone config: `url = http://zurg:9999/dav` (when rclone and zurg share Docker network) or `http://127.0.0.1:9999/dav` (when rclone on host).

### 7. Wrong zurg binary (Exec format error)

**Cause:** Downloaded linux-amd64 zurg on ARM (Pi 5).

**Fix:** Use `zurg-v0.9.x-final-linux-arm64.zip` from [zurg-testing releases](https://github.com/debridmediamanager/zurg-testing/releases).

### 8. Video freezes on seek/skip, audio continues

**Cause:** Jellyfin transcoding bug (especially audio-only transcode: video direct + audio transcoded). When you seek/skip, the transcoder gets out of sync.

**Fixes (try in order):**
1. **Force Direct Play (script)** – `./scripts/servarr/jellyfin-force-direct-play.sh` disables transcoding for all users (or `JF_USER=username` for one). Requires `JELLYFIN_API_KEY` in `scripts/servarr/.env`.
2. **Force Direct Play (manual)** – Dashboard → Users → [your user] → Playback → uncheck both transcoding options.
2. **Different client** – Web, Android TV, iOS, etc. behave differently; try another client.
3. **Force full transcode** – Lower the player bitrate so both video and audio transcode. Some users report this is more stable than audio-only transcode (Jellyfin issue #13716).
5. **Pi 5 note** – No HW acceleration; transcoding is CPU-heavy. Prefer Direct Play when possible.

### 9. VFS cache fills disk (rclone cache full)

**Cause:** `--vfs-cache-mode full` stores files locally; cache can grow until disk is full (rclone doesn't auto-purge on unmount).

**Fix:** Clear cache manually: `rm -rf /mnt/data/appdata/rclone-cache/*`. Ensure `--vfs-cache-max-size 20G` is set to cap growth.

### 10. Jellyseerr connections (Jellyfin, Radarr, Sonarr)

**Cause:** Jellyseerr needs host.docker.internal to reach services on the host; Jellyfin config empty or wrong.

**Fix:** Run `./scripts/servarr/jellyseerr-fix-connections.sh` — configures Jellyfin (API key, server ID), Radarr, Sonarr. Requires `JELLYFIN_API_KEY` in `scripts/servarr/.env`. After restart: Settings → Jellyfin → Sync Libraries.

---

## Alternative: rclone on Host (Maximum Stability)

Docker + FUSE propagation can be fragile. Running rclone on the host (like Unraid) avoids propagation issues.

**Steps:**
1. Install rclone on Pi: `sudo apt install -y rclone`
2. Create `/mnt/data/appdata/zurg/rclone.conf`:
   ```ini
   [zurg]
   type = webdav
   url = http://127.0.0.1:9999/dav
   vendor = other
   pacer_min_sleep = 0
   ```
3. Run Zurg in Docker (port 9999).
4. Create systemd service or User Script to mount:
   ```bash
   rclone mount zurg: /mnt/zurg \
     --dir-cache-time 20s \
     --config=/mnt/data/appdata/zurg/rclone.conf \
     --allow-other --allow-non-empty \
     --vfs-cache-mode full \
     --vfs-read-ahead 512M \
     --vfs-cache-max-size 20G \
     --buffer-size 256M \
     --daemon
   ```
5. Start order: Zurg → rclone → Jellyfin.

See `scripts/servarr/zurg-rclone-host-mount.sh` for a ready-to-use script.

---

## Startup Order Summary

| Order | Service   | Notes                                      |
|-------|-----------|--------------------------------------------|
| 1     | Zurg      | WebDAV must be up before rclone connects    |
| 2     | rclone    | Wait ~10s after Zurg (compose has sleep 10) |
| 3     | Jellyfin  | Must start after /mnt/zurg is populated    |

The setup script's docker-compose includes `sleep 10` before rclone mount (per Unraid guide).

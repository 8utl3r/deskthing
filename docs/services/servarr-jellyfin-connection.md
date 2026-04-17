# Connect Jellyfin to Servarr Stack

When Sonarr/Radarr/Lidarr import content, they trigger a Jellyfin library scan so new media appears immediately. **LazyLibrarian** (books/audiobooks) uses a custom notification script that calls jellyfin-autoscan on download.

## Recommended: jellyfin-autoscan (webhooks)

**Use this** — avoids bugs in the built-in Jellyfin connection (Jellyfin 10.9+ API changes).

From Mac (requires SSH to Pi, `scripts/servarr/.env` with `JELLYFIN_API_KEY`):

```bash
./scripts/servarr-pi5-jellyfin-autoscan-setup.sh
```

This will:
1. Deploy jellyfin-autoscan in Docker on the Pi (builds from GitHub)
2. Remove the built-in Jellyfin connections from Sonarr, Radarr, Lidarr
3. Add Webhook connections to Sonarr, Radarr, Lidarr
4. LazyLibrarian triggers jellyfin-autoscan via custom notification script (see `servarr-pi5-lazylibrarian-setup.sh`)

Test: `curl -X POST http://192.168.0.136:8282/refresh`

## Option A: Built-in Connection (manual)

Add Jellyfin in each *arr app. **Note:** The built-in Jellyfin connection has known issues with Jellyfin 10.9+ (notification API changed). "Update library" may work; test after setup.

### 1. Get Jellyfin API key

1. Open http://192.168.0.136:8096 (or pi5.xcvr.link:8096)
2. Log in as pete
3. Dashboard (hamburger) → **Admin** → **API Keys**
4. Click **+** → name it "Servarr" → OK
5. Copy the API key and add to `scripts/servarr/.env`:
   ```
   JELLYFIN_API_KEY=your_key_here
   ```

### 2. Add connection in each *arr app

| App | URL | Path |
|-----|-----|------|
| Sonarr | http://192.168.0.136:8989 | Settings → Connect |
| Radarr | http://192.168.0.136:7878 | Settings → Connect |
| Lidarr | http://192.168.0.136:8686 | Settings → Connect |
| LazyLibrarian | http://192.168.0.136:5299 | Config → Notifications (custom script) |

For each app:

1. **Add** → **Jellyfin** (or **Emby** if Jellyfin not listed; Jellyfin is Emby-compatible)
2. **Host:** `http://localhost:8096` (or `http://192.168.0.136:8096` if connecting from another machine)
3. **API Key:** paste the key from step 1
4. Enable **Update library** on **Download** and **Upgrade**
5. **Test** → **Save**

### Path note

*arr apps use `/mnt/data/media/*`; Jellyfin (Docker) uses `/media/*` inside the container. Both point to the same files. No remote path mapping needed if everything runs on the Pi.

---

## Option B: Jellyfin-autoscan (if Option A fails)

If the built-in connection doesn't trigger scans, use [jellyfin-autoscan](https://github.com/naakpy/jellyfin-autoscan):

1. Runs as a service on the Pi
2. Receives webhooks from Sonarr/Radarr/Lidarr and custom script from LazyLibrarian
3. Calls Jellyfin API to scan the affected library

Install and configure on the Pi; add webhook URLs in each *arr app (Settings → Connect → Webhook).

---

## Quick reference

| Service | Port | URL |
|---------|------|-----|
| Jellyfin | 8096 | http://pi5.xcvr.link:8096 |
| Sonarr | 8989 | http://pi5.xcvr.link:8989 |
| Radarr | 7878 | http://pi5.xcvr.link:7878 |
| Lidarr | 8686 | http://pi5.xcvr.link:8686 |
| LazyLibrarian | 5299 | http://pi5.xcvr.link:5299 |

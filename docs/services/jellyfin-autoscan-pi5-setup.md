# Jellyfin-Autoscan on Pi 5

Reliable alternative to the built-in Jellyfin connection in *arr apps (which has bugs with Jellyfin 10.9+). LazyLibrarian uses a custom notification script that calls the refresh endpoint.

## Automated setup (from Mac)

```bash
./scripts/servarr-pi5-jellyfin-autoscan-setup.sh
```

Requires: SSH to pi@192.168.0.136, `scripts/servarr/.env` with `JELLYFIN_API_KEY`.

## How it works

1. jellyfin-autoscan runs in Docker, listens on port 8282
2. On any POST to `/refresh`, it triggers Jellyfin's RefreshLibrary task
3. *arr apps send webhooks to that URL when content is imported/upgraded/renamed

## Manual install (on Pi)

```bash
# Create config dir
sudo mkdir -p /var/lib/jellyfin-autoscan
sudo chown 1000:1000 /var/lib/jellyfin-autoscan

# Run jellyfin-autoscan (replace API_KEY with your Jellyfin API key)
docker run -d \
  --name jellyfin-autoscan \
  --restart unless-stopped \
  -p 8282:8282 \
  -e JELLYFIN_BASE_URL=http://host.docker.internal:8096 \
  -e JELLYFIN_API_KEY=YOUR_API_KEY \
  -e LOG_LEVEL=INFO \
  ghcr.io/naakpy/jellyfin-autoscan:latest
```

**Note:** `host.docker.internal` lets the container reach Jellyfin on the host. On Linux you may need `--add-host=host.docker.internal:host-gateway` or use `172.17.0.1` (Docker bridge gateway).

## Webhook setup

Add Webhook in each *arr app (Settings → Connect → Add → Webhook):

| App | URL | Events |
|-----|-----|--------|
| Sonarr | http://localhost:8282/refresh | On Import, On Upgrade, On Rename |
| Radarr | http://localhost:8282/refresh | On Import, On Upgrade, On Rename |
| Lidarr | http://localhost:8282/refresh | On Import, On Upgrade, On Rename |
| LazyLibrarian | Custom script → POST http://192.168.0.136:8282/refresh | On Download (Config → Notifications) |

Method: **POST**

## Remove built-in Jellyfin connections

The built-in Jellyfin/Emby connection has API bugs. Remove it from Sonarr, Radarr, Lidarr (Settings → Connect → delete "Jellyfin") and use webhooks instead.

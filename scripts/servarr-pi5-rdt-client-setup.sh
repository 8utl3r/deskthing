#!/bin/bash
# Deploy rdt-client (Real-Debrid/AllDebrid) on Pi 5
# Run from Mac: ./scripts/servarr-pi5-rdt-client-setup.sh
# Requires: scripts/servarr/.env with REAL_DEBRID_API_KEY
# Configures: API key, categories, auth=None, then adds rdt-client to *arr apps

set -e
PI="${PI_HOST:-pi@192.168.0.136}"
BASE="http://192.168.0.136"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$DOTFILES_ROOT/scripts/servarr/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE. Create from .env.example and set REAL_DEBRID_API_KEY."
  exit 1
fi
source "$ENV_FILE"
: "${REAL_DEBRID_API_KEY:?REAL_DEBRID_API_KEY not set in .env}"

echo "=== Deploy rdt-client on Pi ==="
echo "Target: $PI"
echo ""

ssh "$PI" "bash -s" << REMOTE_SCRIPT
set -e
DOWNLOAD_BASE="/mnt/data/downloads/rdt-client"
DB="\$DOWNLOAD_BASE/db/rdtclient.db"

sudo mkdir -p "\$DOWNLOAD_BASE/db" "\$DOWNLOAD_BASE"
sudo chown -R 1000:1000 "\$DOWNLOAD_BASE" 2>/dev/null || sudo chown -R pi:pi "\$DOWNLOAD_BASE"

sudo docker stop rdt-client 2>/dev/null || true
sudo docker rm rdt-client 2>/dev/null || true

sudo docker run -d \
  --name rdt-client \
  -p 6500:6500 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/Chicago \
  -v "\$DOWNLOAD_BASE/db:/data/db" \
  -v "\$DOWNLOAD_BASE:/data/downloads" \
  --restart unless-stopped \
  rogerfar/rdtclient

echo "Waiting for DB creation..."
sleep 5
sudo docker stop rdt-client 2>/dev/null || true
sleep 2

if [ -f "\$DB" ]; then
  sqlite3 "\$DB" "UPDATE Settings SET Value='$REAL_DEBRID_API_KEY' WHERE SettingId='Provider:ApiKey';"
  sqlite3 "\$DB" "UPDATE Settings SET Value='radarr, sonarr, lidarr, lazylibrarian' WHERE SettingId='General:Categories';"
  sqlite3 "\$DB" "UPDATE Settings SET Value='None' WHERE SettingId='General:AuthenticationType';"
  echo "Configured API key, categories, auth=None"
fi

sudo docker start rdt-client
echo "rdt-client started. Waiting 5s..."
sleep 5
REMOTE_SCRIPT

echo ""
echo "=== Add rdt-client to *arr apps ==="
SONARR_KEY="676e7d8835274485b137224eb4501445"
RADARR_KEY="0d62868ed45448049b5aa402e756e4fc"
LIDARR_KEY="8c2ba7c1ab3c419daed8c84ab817b767"

for app in "radarr:$RADARR_KEY:7878:v3:movieCategory:movieImportedCategory:radarr" "sonarr:$SONARR_KEY:8989:v3:tvCategory:tvImportedCategory:sonarr" "lidarr:$LIDARR_KEY:8686:v1:musicCategory:musicImportedCategory:lidarr"; do
  IFS=':' read -r name key port ver catF impF catVal <<< "$app"
  echo -n "  $name: "
  resp=$(curl -s -X POST "$BASE:$port/api/$ver/downloadclient" -H "X-Api-Key: $key" -H "Content-Type: application/json" \
    -d "{\"enable\":true,\"protocol\":\"torrent\",\"priority\":1,\"name\":\"rdt-client\",\"implementation\":\"QBittorrent\",\"configContract\":\"QBittorrentSettings\",\"fields\":[{\"name\":\"host\",\"value\":\"127.0.0.1\"},{\"name\":\"port\",\"value\":6500},{\"name\":\"useSsl\",\"value\":false},{\"name\":\"urlBase\",\"value\":\"\"},{\"name\":\"username\",\"value\":\"\"},{\"name\":\"password\",\"value\":\"\"},{\"name\":\"$catF\",\"value\":\"$catVal\"},{\"name\":\"$impF\",\"value\":\"$catVal\"}]}")
  echo "$resp" | grep -q '"id"' && echo "OK" || echo "skip (may exist)"
done

echo ""
echo "=== Done ==="
echo "rdt-client: http://pi5.xcvr.link:6500"
echo "See: docs/services/servarr-pi5-indexers-debrid-setup.md"

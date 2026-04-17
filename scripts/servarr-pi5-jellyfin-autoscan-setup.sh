#!/bin/bash
# Deploy jellyfin-autoscan and switch *arr apps from built-in Jellyfin to webhooks
# Run from Mac: ./scripts/servarr-pi5-jellyfin-autoscan-setup.sh
# Requires: SSH to pi@192.168.0.136, dotfiles on Pi at ~/dotfiles (or PI_DOTFILES path)

set -e
PI="${PI_HOST:-pi@192.168.0.136}"
BASE="http://192.168.0.136"
SONARR_KEY="676e7d8835274485b137224eb4501445"
RADARR_KEY="0d62868ed45448049b5aa402e756e4fc"
LIDARR_KEY="8c2ba7c1ab3c419daed8c84ab817b767"
WEBHOOK_URL="http://localhost:8282/refresh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$DOTFILES_ROOT/scripts/servarr/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE. Create from .env.example and set JELLYFIN_API_KEY."
  exit 1
fi

echo "=== 1. Deploy jellyfin-autoscan on Pi ==="
REMOTE_DIR="/tmp/jellyfin-autoscan-setup"
echo "Copying files to Pi..."
ssh "$PI" "mkdir -p $REMOTE_DIR"
scp -q "$ENV_FILE" "$PI:$REMOTE_DIR/.env"
scp -q "$DOTFILES_ROOT/scripts/servarr/jellyfin-autoscan-docker-compose.yml" "$PI:$REMOTE_DIR/"

echo "Building and starting jellyfin-autoscan (may take 1-2 min first time)..."
# Pi may not have docker-compose; use docker run
ssh "$PI" 'bash -s' << 'REMOTE_SCRIPT'
set -e
REMOTE_DIR="/tmp/jellyfin-autoscan-setup"
cd "$REMOTE_DIR"
source .env
# Stop existing if any
sudo docker stop jellyfin-autoscan 2>/dev/null || true
sudo docker rm jellyfin-autoscan 2>/dev/null || true
# Build image (git URL as context works in Docker 20.10+)
sudo docker build -t jellyfin-autoscan:local https://github.com/naakpy/jellyfin-autoscan.git#main
# Run with host network so it can reach Jellyfin on localhost:8096
sudo docker run -d \
  --name jellyfin-autoscan \
  --restart unless-stopped \
  --network host \
  -e JELLYFIN_BASE_URL=http://127.0.0.1:8096 \
  -e JELLYFIN_API_KEY="$JELLYFIN_API_KEY" \
  -e LOG_LEVEL=INFO \
  jellyfin-autoscan:local
REMOTE_SCRIPT

echo "Waiting for autoscan to start..."
sleep 5
if curl -s -o /dev/null -w "%{http_code}" -X POST "http://$BASE:8282/refresh" | grep -q 200; then
  echo "  Autoscan is responding"
else
  echo "  Warning: autoscan may not be ready yet. Continuing..."
fi

echo ""
echo "=== 2. Remove built-in Jellyfin connections ==="
for app in "Radarr:$RADARR_KEY:7878:v3" "Sonarr:$SONARR_KEY:8989:v3" "Lidarr:$LIDARR_KEY:8686:v1"; do
  IFS=':' read -r name key port ver <<< "$app"
  echo -n "  $name: "
  id=$(curl -s "$BASE:$port/api/$ver/notification" -H "X-Api-Key: $key" | \
    python3 -c "import json,sys; d=json.load(sys.stdin); x=[n for n in d if n.get('name')=='Jellyfin']; print(x[0]['id'] if x else '')" 2>/dev/null)
  if [ -n "$id" ]; then
    curl -s -X DELETE "$BASE:$port/api/$ver/notification/$id" -H "X-Api-Key: $key" -o /dev/null
    echo "removed"
  else
    echo "not found"
  fi
done

echo ""
echo "=== 3. Add Webhook connections ==="
# Radarr
echo -n "Radarr webhook: "
curl -s -X POST "$BASE:7878/api/v3/notification" \
  -H "X-Api-Key: $RADARR_KEY" -H "Content-Type: application/json" \
  -d '{
    "onDownload":true,"onUpgrade":true,"onRename":true,
    "onMovieDelete":true,"onMovieFileDelete":true,"onMovieFileDeleteForUpgrade":true,
    "name":"Jellyfin-Autoscan","implementation":"Webhook","configContract":"WebhookSettings",
    "fields":[{"name":"url","value":"'"$WEBHOOK_URL"'"},{"name":"method","value":1}],
    "tags":[]
  }' | python3 -c "import json,sys; d=json.load(sys.stdin); print('OK' if d.get('id') else 'Error: '+str(d.get('message',d)))"

# Sonarr
echo -n "Sonarr webhook: "
curl -s -X POST "$BASE:8989/api/v3/notification" \
  -H "X-Api-Key: $SONARR_KEY" -H "Content-Type: application/json" \
  -d '{
    "onDownload":true,"onUpgrade":true,"onImportComplete":true,"onRename":true,
    "onSeriesDelete":true,"onEpisodeFileDelete":true,"onEpisodeFileDeleteForUpgrade":true,
    "name":"Jellyfin-Autoscan","implementation":"Webhook","configContract":"WebhookSettings",
    "fields":[{"name":"url","value":"'"$WEBHOOK_URL"'"},{"name":"method","value":1}],
    "tags":[]
  }' | python3 -c "import json,sys; d=json.load(sys.stdin); print('OK' if d.get('id') else 'Error: '+str(d.get('message',d)))"

# Lidarr
echo -n "Lidarr webhook: "
curl -s -X POST "$BASE:8686/api/v1/notification" \
  -H "X-Api-Key: $LIDARR_KEY" -H "Content-Type: application/json" \
  -d '{
    "onReleaseImport":true,"onUpgrade":true,"onRename":true,
    "onArtistDelete":true,"onAlbumDelete":true,
    "name":"Jellyfin-Autoscan","implementation":"Webhook","configContract":"WebhookSettings",
    "fields":[{"name":"url","value":"'"$WEBHOOK_URL"'"},{"name":"method","value":1}],
    "tags":[]
  }' | python3 -c "import json,sys; d=json.load(sys.stdin); print('OK' if d.get('id') else 'Error: '+str(d.get('message',d)))"

# Readarr removed — LazyLibrarian uses custom notification script instead

echo ""
echo "=== Done ==="
echo "jellyfin-autoscan: http://localhost:8282/refresh"
echo "Test: curl -X POST http://192.168.0.136:8282/refresh"

#!/bin/bash
# Add Jellyfin connection to Sonarr, Radarr, Lidarr (books via LazyLibrarian + jellyfin-autoscan)
# Run from Mac: ./scripts/servarr-pi5-add-jellyfin-connections.sh
# Requires: scripts/servarr/.env with JELLYFIN_API_KEY

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVARR_DIR="$SCRIPT_DIR/servarr"
ENV_FILE="$SERVARR_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE. Create from .env.example and set JELLYFIN_API_KEY."
  exit 1
fi
source "$ENV_FILE"
: "${JELLYFIN_API_KEY:?Set JELLYFIN_API_KEY in $ENV_FILE}"

BASE="http://192.168.0.136"
SONARR_KEY="676e7d8835274485b137224eb4501445"
RADARR_KEY="0d62868ed45448049b5aa402e756e4fc"
LIDARR_KEY="8c2ba7c1ab3c419daed8c84ab817b767"

JF_FIELDS='[
  {"name":"host","value":"localhost"},
  {"name":"port","value":8096},
  {"name":"useSsl","value":false},
  {"name":"urlBase","value":""},
  {"name":"apiKey","value":"'"$JELLYFIN_API_KEY"'"},
  {"name":"notify","value":false},
  {"name":"updateLibrary","value":true},
  {"name":"mapFrom","value":"/mnt/data/media"},
  {"name":"mapTo","value":"/media"}
]'

echo "=== Adding Jellyfin connection to *arr apps ==="

echo -n "Radarr: "
curl -s -X POST "$BASE:7878/api/v3/notification" \
  -H "X-Api-Key: $RADARR_KEY" -H "Content-Type: application/json" \
  -d '{
    "onDownload":true,"onUpgrade":true,"onRename":true,
    "onMovieDelete":true,"onMovieFileDelete":true,"onMovieFileDeleteForUpgrade":true,
    "name":"Jellyfin","implementation":"MediaBrowser","configContract":"MediaBrowserSettings",
    "fields":'"$JF_FIELDS"',"tags":[]
  }' | python3 -c "import json,sys; d=json.load(sys.stdin); print('OK' if d.get('id') else 'Error: '+str(d.get('message',d)))"

echo -n "Sonarr: "
curl -s -X POST "$BASE:8989/api/v3/notification" \
  -H "X-Api-Key: $SONARR_KEY" -H "Content-Type: application/json" \
  -d '{
    "onDownload":true,"onUpgrade":true,"onImportComplete":true,"onRename":true,
    "onSeriesDelete":true,"onEpisodeFileDelete":true,"onEpisodeFileDeleteForUpgrade":true,
    "name":"Jellyfin","implementation":"MediaBrowser","configContract":"MediaBrowserSettings",
    "fields":'"$JF_FIELDS"',"tags":[]
  }' | python3 -c "import json,sys; d=json.load(sys.stdin); print('OK' if d.get('id') else 'Error: '+str(d.get('message',d)))"

echo -n "Lidarr: "
curl -s -X POST "$BASE:8686/api/v1/notification" \
  -H "X-Api-Key: $LIDARR_KEY" -H "Content-Type: application/json" \
  -d '{
    "onReleaseImport":true,"onUpgrade":true,"onRename":true,
    "onArtistDelete":true,"onAlbumDelete":true,
    "name":"Jellyfin","implementation":"MediaBrowser","configContract":"MediaBrowserSettings",
    "fields":'"$JF_FIELDS"',"tags":[]
  }' | python3 -c "import json,sys; d=json.load(sys.stdin); print('OK' if d.get('id') else 'Error: '+str(d.get('message',d)))"

echo ""
echo "=== Done ==="
echo "Books/audiobooks: LazyLibrarian uses custom notification script to trigger jellyfin-autoscan."

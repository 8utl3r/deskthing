#!/bin/bash
# Fix Jellyseerr connections: Jellyfin + Radarr + Sonarr
# Run from Mac: ./scripts/servarr/jellyseerr-fix-connections.sh
#
# Ensures:
# - Jellyfin: host.docker.internal:8096, API key, server ID
# - Radarr: host.docker.internal:7878
# - Sonarr: host.docker.internal:8989

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
PI="${PI_HOST:-pi@192.168.0.136}"
BASE="http://192.168.0.136"
JF_PORT="${JELLYFIN_PORT:-8096}"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: $ENV_FILE not found"
  exit 1
fi

source "$ENV_FILE"
JELLYFIN_API_KEY="${JELLYFIN_API_KEY:-}"
RADARR_KEY="${RADARR_KEY:-0d62868ed45448049b5aa402e756e4fc}"
SONARR_KEY="${SONARR_KEY:-676e7d8835274485b137224eb4501445}"

if [ -z "$JELLYFIN_API_KEY" ]; then
  echo "Error: JELLYFIN_API_KEY not set in $ENV_FILE"
  exit 1
fi

echo "=== Jellyseerr: Fix connections ==="
echo "Target: $PI"
echo ""

# Get Jellyfin server ID
echo "Fetching Jellyfin server ID..."
JF_SERVER_ID=$(curl -s "$BASE:$JF_PORT/System/Info" -H "X-Emby-Token: $JELLYFIN_API_KEY" 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('Id',''))" 2>/dev/null || echo "")
if [ -z "$JF_SERVER_ID" ]; then
  echo "Warning: Could not reach Jellyfin at $BASE:$JF_PORT. Jellyfin config may be incomplete."
fi

# Create config script
SCRIPT=$(mktemp)
cat << PYSCRIPT > "$SCRIPT"
import json
import os

path = '/mnt/data/appdata/jellyseerr/settings.json'
jf_api = os.environ.get('JELLYFIN_API_KEY', '')
jf_server_id = os.environ.get('JF_SERVER_ID', '')
radarr_key = os.environ.get('RADARR_KEY', '')
sonarr_key = os.environ.get('SONARR_KEY', '')

with open(path, 'r') as f:
    s = json.load(f)

# Jellyfin
s['jellyfin'] = {
    "name": "Jellyfin",
    "ip": "host.docker.internal",
    "port": 8096,
    "useSsl": False,
    "urlBase": "",
    "externalHostname": "http://pi5.xcvr.link:8096",
    "jellyfinForgotPasswordUrl": "",
    "libraries": s.get('jellyfin', {}).get('libraries', []),
    "serverId": jf_server_id,
    "apiKey": jf_api
}

# Radarr
s['radarr'] = [{
    "name": "Radarr",
    "hostname": "host.docker.internal",
    "port": 7878,
    "useSsl": False,
    "apiKey": radarr_key,
    "urlBase": "",
    "rootFolder": "/mnt/data/media/movies",
    "qualityProfile": "HD-1080p",
    "minimumAvailability": "released",
    "isDefault": True,
    "is4k": False,
    "externalUrl": "",
    "enableScan": True,
    "enableAutomaticSearch": True,
    "syncEnabled": True
}]

# Sonarr
s['sonarr'] = [{
    "name": "Sonarr",
    "hostname": "host.docker.internal",
    "port": 8989,
    "useSsl": False,
    "apiKey": sonarr_key,
    "urlBase": "",
    "rootFolder": "/mnt/data/media/tv",
    "qualityProfile": "HD-1080p",
    "minimumAvailability": "released",
    "isDefault": True,
    "is4k": False,
    "externalUrl": "",
    "enableScan": True,
    "enableAutomaticSearch": True,
    "syncEnabled": True
}]

with open(path, 'w') as f:
    json.dump(s, f, indent=1)

print('Updated: jellyfin, radarr, sonarr')
PYSCRIPT

scp -q "$SCRIPT" "$PI:/tmp/jellyseerr_fix.py"
rm -f "$SCRIPT"

ssh "$PI" "JELLYFIN_API_KEY='$JELLYFIN_API_KEY' JF_SERVER_ID='$JF_SERVER_ID' RADARR_KEY='$RADARR_KEY' SONARR_KEY='$SONARR_KEY' sudo -E python3 /tmp/jellyseerr_fix.py"
ssh "$PI" "rm -f /tmp/jellyseerr_fix.py"

echo ""
echo "Restarting Jellyseerr..."
ssh "$PI" "sudo docker restart jellyseerr"

echo ""
echo "Done. Jellyseerr: http://pi5.xcvr.link:5055"
echo "  Jellyfin: host.docker.internal:8096"
echo "  Radarr: host.docker.internal:7878"
echo "  Sonarr: host.docker.internal:8989"
echo ""
echo "After restart: Settings → Jellyfin → Sync Libraries to pull library list."

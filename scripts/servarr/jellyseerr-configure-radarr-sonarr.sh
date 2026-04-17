#!/bin/bash
# Add Radarr and Sonarr to Jellyseerr settings.json on Pi 5
# Run from Mac: ./scripts/servarr/jellyseerr-configure-radarr-sonarr.sh
# Requires: ssh access to Pi, python3 on Pi

set -e
PI="${PI_HOST:-pi@192.168.0.136}"
RADARR_KEY="0d62868ed45448049b5aa402e756e4fc"
SONARR_KEY="676e7d8835274485b137224eb4501445"

echo "=== Jellyseerr: Add Radarr + Sonarr ==="
echo "Target: $PI"
echo ""

# Create Python script that uses env vars (avoids quote escaping)
SCRIPT=$(mktemp)
cat << 'PYSCRIPT' > "$SCRIPT"
import json
import os

path = '/mnt/data/appdata/jellyseerr/settings.json'
radarr_key = os.environ.get('RADARR_KEY', '')
sonarr_key = os.environ.get('SONARR_KEY', '')

radarr = {
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
}

sonarr = {
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
}

with open(path, 'r') as f:
    s = json.load(f)

s['radarr'] = [radarr]
s['sonarr'] = [sonarr]

with open(path, 'w') as f:
    json.dump(s, f, indent=1)

print('Updated settings.json: radarr and sonarr configured')
PYSCRIPT

# Copy script to Pi and run with env vars
scp -q "$SCRIPT" "$PI:/tmp/jellyseerr_config.py"
rm -f "$SCRIPT"
ssh "$PI" "RADARR_KEY='$RADARR_KEY' SONARR_KEY='$SONARR_KEY' sudo -E python3 /tmp/jellyseerr_config.py"
ssh "$PI" "rm -f /tmp/jellyseerr_config.py"

echo ""
echo "Restarting Jellyseerr to apply changes..."
ssh "$PI" "sudo docker restart jellyseerr"
echo ""
echo "Done. Jellyseerr: http://192.168.0.136:5055"
echo "Radarr: host.docker.internal:7878, Sonarr: host.docker.internal:8989"

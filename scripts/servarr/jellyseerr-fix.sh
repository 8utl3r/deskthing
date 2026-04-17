#!/bin/bash
# Fix Jellyseerr: recreate container with host.docker.internal so it can reach Radarr/Sonarr on the host
# Run from Mac: ./scripts/servarr/jellyseerr-fix.sh

set -e
PI="${PI_HOST:-pi@192.168.0.136}"
BASE="http://192.168.0.136"

echo "=== Jellyseerr fix: add host.docker.internal ==="
echo "Target: $PI"
echo ""

ssh "$PI" "sudo docker stop jellyseerr 2>/dev/null || true; sudo docker rm jellyseerr 2>/dev/null || true"
ssh "$PI" "sudo mkdir -p /mnt/data/appdata/jellyseerr"
ssh "$PI" "sudo docker run -d --name jellyseerr --restart unless-stopped \
  -p 5055:5055 \
  -e TZ=America/Chicago \
  -e LOG_LEVEL=info \
  --add-host=host.docker.internal:host-gateway \
  -v /mnt/data/appdata/jellyseerr:/app/config \
  ghcr.io/fallenbagel/jellyseerr:latest"

echo ""
echo "Jellyseerr recreated. Config preserved."
echo ""
echo "If Radarr/Sonarr were set to localhost, update in Jellyseerr UI:"
echo "  Settings → Radarr → edit → Hostname: host.docker.internal, Port: 7878"
echo "  Settings → Sonarr → edit → Hostname: host.docker.internal, Port: 8989"
echo ""
echo "URL: $BASE:5055"

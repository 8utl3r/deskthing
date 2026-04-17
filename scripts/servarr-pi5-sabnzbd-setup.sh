#!/bin/bash
# Deploy Sabnzbd on Pi 5 for Usenet (NewsgroupDirect)
# Run from Mac: ./scripts/servarr-pi5-sabnzbd-setup.sh
# After deploy: open http://pi5.xcvr.link:8085 and add NewsgroupDirect server + API key

set -e
PI="${PI_HOST:-pi@192.168.0.136}"

echo "=== Deploy Sabnzbd on Pi ==="
echo "Target: $PI"
echo "Port: 8085 (qBittorrent uses 8080)"
echo ""

ssh "$PI" 'bash -s' << 'REMOTE_SCRIPT'
set -e
BASE="/mnt/data/downloads/sabnzbd"
sudo mkdir -p "$BASE/config" "$BASE/incomplete" "$BASE/complete"
sudo chown -R 1000:1000 "$BASE" 2>/dev/null || sudo chown -R pi:pi "$BASE"

sudo docker stop sabnzbd 2>/dev/null || true
sudo docker rm sabnzbd 2>/dev/null || true

sudo docker run -d \
  --name sabnzbd \
  -p 8085:8080 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/Chicago \
  -v "$BASE/config:/config" \
  -v "$BASE:/downloads" \
  --restart unless-stopped \
  lscr.io/linuxserver/sabnzbd:latest

echo "Sabnzbd started. Waiting 5s..."
sleep 5
REMOTE_SCRIPT

echo ""
echo "=== Done ==="
echo "Sabnzbd: http://pi5.xcvr.link:8085"
echo ""
echo "Next steps:"
echo "  1. Complete setup wizard"
echo "  2. Config → Servers: Add news.newsgroupdirect.com:563 (SSL), your username/password"
echo "  3. Config → Categories: radarr, sonarr, lidarr, lazylibrarian"
echo "  4. Config → General: Note API key"
echo "  5. Add Sabnzbd as download client in Radarr/Sonarr/Lidarr (+ LazyLibrarian for books)"
echo ""
echo "See: docs/services/servarr-pi5-usenet-setup.md"

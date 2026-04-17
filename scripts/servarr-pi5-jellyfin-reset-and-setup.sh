#!/bin/bash
# Reset Jellyfin to fresh state and run full CLI setup
# Run ON THE PI: sudo bash servarr-pi5-jellyfin-reset-and-setup.sh
# Requires: Jellyfin installed, /mnt/data/media dirs exist

set -e
JF_USER="${JF_USER:-admin}"
JF_PASS="${JF_PASS:-servarr2026}"
DATA_BASE="${DATA_BASE:-/mnt/data/media}"

echo "=== 1. Stop Jellyfin ==="
systemctl stop jellyfin 2>/dev/null || true
sleep 2

echo "=== 2. Backup and clear Jellyfin data (reset wizard) ==="
JF_DATA="/var/lib/jellyfin"
if [ -d "$JF_DATA" ]; then
  BACKUP="$JF_DATA.bak.$(date +%Y%m%d%H%M%S)"
  mv "$JF_DATA" "$BACKUP"
  echo "Backed up to $BACKUP"
fi
mkdir -p "$JF_DATA"
chown jellyfin:jellyfin "$JF_DATA"

echo "=== 3. Start Jellyfin ==="
systemctl start jellyfin
echo "Waiting for Jellyfin to initialize (60s)..."
sleep 60

echo "=== 4. Run CLI setup ==="
export JF_USER JF_PASS DATA_BASE
export JF_BASE="http://localhost:8096"
bash "$(dirname "$0")/servarr-pi5-jellyfin-cli-setup.sh"

echo "=== 5. Create test user (via API) ==="
AUTH=$(curl -s -X POST "http://localhost:8096/Users/AuthenticateByName" \
  -H "Authorization: MediaBrowser Client=\"setup\", Device=\"script\", DeviceId=\"setup-1\", Version=\"1.0\"" \
  -H "Content-Type: application/json" \
  -d "{\"Username\":\"$JF_USER\",\"Pw\":\"$JF_PASS\"}")
TOKEN=$(echo "$AUTH" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('AccessToken',''))" 2>/dev/null)
if [ -n "$TOKEN" ]; then
  curl -s -X POST "http://localhost:8096/Users/New" \
    -H "Authorization: MediaBrowser Token=\"$TOKEN\"" \
    -H "Content-Type: application/json" \
    -d '{"Name":"test","Password":"test1234","EnableAutoLogin":false}' \
    -w " (test user) HTTP %{http_code}\n" -o /dev/null
  echo "Test account: test / test1234"
else
  echo "Could not create test user (auth failed)"
fi

echo ""
echo "=== Done ==="
echo "Admin: $JF_USER / $JF_PASS"
echo "Test:  test / test1234"
echo "URL:   http://pi5.xcvr.link:8096"

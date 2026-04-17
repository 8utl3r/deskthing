#!/bin/bash
# Fresh Jellyfin setup: reset data, start, configure via Startup API
# Run ON THE PI: sudo JF_PASS=12345678 bash servarr-pi5-jellyfin-fresh-setup.sh
# Or from Mac: ssh pi@pi5.xcvr.link 'JF_PASS=12345678 sudo bash -s' < scripts/servarr-pi5-jellyfin-fresh-setup.sh

set -e
JF_USER="${JF_USER:-admin}"
JF_PASS="${JF_PASS:-12345678}"
DATA_BASE="${DATA_BASE:-/mnt/data/media}"
BASE="http://localhost:8096"

echo "=== 1. Stop Jellyfin ==="
systemctl stop jellyfin 2>/dev/null || true
sleep 3

echo "=== 2. Backup and clear Jellyfin data ==="
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
echo "Waiting for Jellyfin to initialize (90s)..."
sleep 90

echo "=== 4. Wait for Startup API ==="
for i in $(seq 1 60); do
  code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/Startup/Configuration" 2>/dev/null || echo "000")
  if [ "$code" = "200" ]; then
    echo "Startup API ready"
    break
  fi
  if [ "$code" = "401" ]; then
    echo "Wizard already complete - cannot run fresh setup. Complete reset may have failed."
    exit 1
  fi
  [ $i -eq 60 ] && { echo "Timeout waiting for Startup API (last code: $code)"; exit 1; }
  sleep 2
done

echo "=== 5. Startup configuration ==="
curl -s -X POST "$BASE/Startup/Configuration" \
  -H "Content-Type: application/json" \
  -d '{"UICulture":"en-US","MetadataCountryCode":"US","PreferredMetadataLanguage":"en"}' \
  -w " HTTP %{http_code}\n" -o /dev/null

echo "=== 6. Create admin user ==="
resp=$(curl -s -w "\n%{http_code}" -X POST "$BASE/Startup/User" \
  -H "Content-Type: application/json" \
  -d "{\"Name\":\"$JF_USER\",\"Password\":\"$JF_PASS\"}")
code=$(echo "$resp" | tail -1)
body=$(echo "$resp" | sed '$d')
if [ "$code" != "204" ] && [ "$code" != "200" ]; then
  echo "User creation failed (HTTP $code): $body"
  exit 1
fi
echo "Admin user created"

echo "=== 7. Add libraries ==="
for lib in "Movies:movies:movies" "TV Shows:tvshows:tv" "Music:music:music" "Books:books:books"; do
  name="${lib%%:*}"
  rest="${lib#*:}"
  ctype="${rest%%:*}"
  subdir="${rest#*:}"
  path="$DATA_BASE/$subdir"
  echo "  $name -> $path"
  curl -s -X POST "$BASE/Library/VirtualFolders" \
    -H "Content-Type: application/json" \
    -d "{\"Name\":\"$name\",\"CollectionType\":\"$ctype\",\"Paths\":[\"$path\"],\"RefreshLibrary\":false}" \
    -w " HTTP %{http_code}\n" -o /dev/null
done

echo "=== 8. Remote access ==="
curl -s -X POST "$BASE/Startup/RemoteAccess" \
  -H "Content-Type: application/json" \
  -d '{"EnableRemoteAccess":true,"EnableAutomaticPortMapping":false}' \
  -w " HTTP %{http_code}\n" -o /dev/null

echo "=== 9. Complete wizard ==="
curl -s -X POST "$BASE/Startup/Complete" -w " HTTP %{http_code}\n" -o /dev/null

echo ""
echo "=== Done ==="
echo "Admin: $JF_USER / $JF_PASS"
echo "URL:   http://pi5.xcvr.link:8096"
echo "Change the password in Dashboard → Users after first login."

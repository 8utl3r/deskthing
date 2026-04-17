#!/bin/bash
# Jellyfin full CLI setup via Startup API (no web wizard needed)
# Run on Pi: sudo -u jellyfin bash servarr-pi5-jellyfin-cli-setup.sh
# Or from Mac: ssh pi@pi5.xcvr.link 'bash -s' < servarr-pi5-jellyfin-cli-setup.sh
# Prerequisites: Jellyfin installed and running, /mnt/data/media dirs exist

set -e
BASE="${JF_BASE:-http://localhost:8096}"
JF_USER="${JF_USER:-admin}"
JF_PASS="${JF_PASS:-admin}"
DATA_BASE="${DATA_BASE:-/mnt/data/media}"

echo "=== 1. Wait for Jellyfin ==="
while ! curl -s --max-time 5 --fail "$BASE/health" >/dev/null 2>&1; do
  echo "Waiting for Jellyfin on $BASE..."
  sleep 2
done
echo "Jellyfin health OK, waiting for Startup API (up to 90s)..."
for i in $(seq 1 45); do
  code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/Startup/Configuration" 2>/dev/null || echo "000")
  [ "$code" = "200" ] && { echo "Startup API ready"; break; }
  [ "$code" = "401" ] && { echo "Wizard already complete"; break; }
  sleep 2
done
echo "Jellyfin is up"

echo "=== 2. Startup configuration ==="
curl -s -X POST "$BASE/Startup/Configuration" \
  -H "Content-Type: application/json" \
  -d '{"UICulture":"en-US","MetadataCountryCode":"US","PreferredMetadataLanguage":"en"}' \
  -w " HTTP %{http_code}\n" -o /dev/null

echo "=== 3. Create admin user ==="
curl -s -X POST "$BASE/Startup/User" \
  -H "Content-Type: application/json" \
  -d "{\"Name\":\"$JF_USER\",\"Password\":\"$JF_PASS\"}" \
  -w " HTTP %{http_code}\n" -o /dev/null

echo "=== 4. Add libraries ==="
for lib in "Movies:movies:movies" "TV Shows:tvshows:tv" "Music:music:music" "Books:books:books"; do
  name="${lib%%:*}"
  ctype="${lib#*:}"
  ctype="${ctype%%:*}"
  subdir="${lib##*:}"
  path="$DATA_BASE/$subdir"
  echo "  $name -> $path"
  curl -s -X POST "$BASE/Library/VirtualFolders" \
    -H "Content-Type: application/json" \
    -d "{\"Name\":\"$name\",\"CollectionType\":\"$ctype\",\"Paths\":[\"$path\"],\"RefreshLibrary\":false}" \
    -w " HTTP %{http_code}\n" -o /dev/null
done

echo "=== 5. Remote access ==="
curl -s -X POST "$BASE/Startup/RemoteAccess" \
  -H "Content-Type: application/json" \
  -d '{"EnableRemoteAccess":true,"EnableAutomaticPortMapping":false}' \
  -w " HTTP %{http_code}\n" -o /dev/null

echo "=== 6. Complete wizard ==="
curl -s -X POST "$BASE/Startup/Complete" -w " HTTP %{http_code}\n" -o /dev/null

echo "=== Done ==="
echo "Jellyfin: $BASE"
echo "Login: $JF_USER / $JF_PASS"
echo "Libraries: Movies, TV Shows, Music, Books"

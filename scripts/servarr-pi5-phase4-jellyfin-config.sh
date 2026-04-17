#!/bin/bash
# Phase 4: Add Jellyfin libraries (run AFTER completing setup wizard)
# Run from Mac: ./servarr-pi5-phase4-jellyfin-config.sh
# Prerequisites: complete Jellyfin setup wizard at http://pi5.xcvr.link:8096

set -e
BASE="http://192.168.0.136:8096"
JF_USER="${JF_USER:-admin}"
JF_PASS="${JF_PASS:-}"
DATA_BASE="/mnt/data/media"

if [ -z "$JF_PASS" ]; then
  echo "Usage: JF_PASS=your_admin_password $0"
  echo "Or: JF_USER=admin JF_PASS=your_admin_password $0"
  exit 1
fi

echo "=== 1. Authenticate to Jellyfin ==="
AUTH_RESP=$(curl -s -X POST "$BASE/Users/AuthenticateByName" \
  -H "Authorization: MediaBrowser Client=\"phase4\", Device=\"script\", DeviceId=\"phase4-script\", Version=\"1.0\"" \
  -H "Content-Type: application/json" \
  -d "{\"Username\":\"$JF_USER\",\"Pw\":\"$JF_PASS\"}")

TOKEN=$(echo "$AUTH_RESP" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('AccessToken',''))" 2>/dev/null)
if [ -z "$TOKEN" ]; then
  echo "Auth failed. Check username/password. Response: $AUTH_RESP"
  exit 1
fi
echo "Authenticated OK"

echo "=== 2. Add media libraries ==="
# Paths are container paths (Docker mounts: /media/movies, etc.)
for lib in "Movies:movies:/media/movies" "TV Shows:tvshows:/media/tv" "Music:music:/media/music" "Books:books:/media/books" "Audiobooks:books:/media/audiobooks"; do
  name="${lib%%:*}"
  rest="${lib#*:}"
  ctype="${rest%%:*}"
  path="${rest#*:}"
  echo "Adding library: $name ($ctype) -> $path"
  # Jellyfin API expects name, collectionType, paths as QUERY params, not JSON body
  path_encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$path'))")
  name_encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$name'))")
  code=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    "$BASE/Library/VirtualFolders?name=$name_encoded&collectionType=$ctype&paths=$path_encoded&refreshLibrary=true" \
    -H "Authorization: MediaBrowser Token=\"$TOKEN\"")
  echo "  HTTP: $code"
done

echo "=== Done ==="
echo "Jellyfin: $BASE"
echo "Libraries: Movies, TV Shows, Music, Books, Audiobooks (container paths: /media/*)"
echo "Note: Pi 5 has no hardware encoders; transcoding uses CPU. Prefer Direct Play."

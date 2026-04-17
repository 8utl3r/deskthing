#!/bin/bash
# Configure LazyLibrarian via API
# Run from Mac: ./scripts/servarr-pi5-lazylibrarian-config-automate.sh
# Requires: scripts/servarr/.env with LAZYLIBRARIAN_API_KEY, SABNZBD_API_KEY
# Also uses: JELLYFIN_API_KEY (Jellyfin libraries), PROWLARR_KEY (from script)
#
# Configures: ebook/audio paths, providers (Newznab/Torznab), qBittorrent,
# Sabnzbd, custom notification script. Jellyfin Books/Audiobooks libraries if JELLYFIN_API_KEY set.
# Sabnzbd category lazylibrarian must be added manually (Config → Categories).

set -e
BASE="http://192.168.0.136"
PROWLARR_KEY="d1ad18607147432bb971559bcc32b888"
QB_PASS="adminadmin"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/servarr/.env"

if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

: "${LAZYLIBRARIAN_API_KEY:?Set LAZYLIBRARIAN_API_KEY in $ENV_FILE}"
LL_API="http://192.168.0.136:5299/api?apikey=$LAZYLIBRARIAN_API_KEY"

wcfg() {
  local name="$1" group="${2:-Config}" value="$3"
  local enc_name enc_group enc_val
  enc_name=$(python3 -c "import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1]))" "$name")
  enc_group=$(python3 -c "import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1]))" "$group")
  enc_val=$(printf '%s' "$value" | python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.stdin.read(), safe=""))')
  curl -s "${LL_API}&cmd=writeCFG&name=${enc_name}&group=${enc_group}&value=${enc_val}" -o /dev/null
}

echo "=== LazyLibrarian API configuration ==="
echo "Target: $BASE:5299"
echo ""

# 1. Ebook & Audio paths and formats
echo "=== 1. Ebook & Audio config ==="
wcfg "ebook_dir" "Config" "/books"
wcfg "ebook_format" "Config" "epub,mobi,pdf"
wcfg "audio_dir" "Config" "/audiobooks"
wcfg "audio_format" "Config" "mp3,m4b"
echo "  ebook_dir=/books, ebook_format=epub,mobi,pdf"
echo "  audio_dir=/audiobooks, audio_format=mp3,m4b"

# 2. Disable magazines (optional)
echo ""
echo "=== 2. Magazines ==="
wcfg "magazine_dir" "Config" ""
wcfg "ENABLE_MAG" "Config" "0"
echo "  Magazines disabled"

# 3. Providers: Newznab (NZBgeek, NzbPlanet) and Torznab (LimeTorrents)
echo ""
echo "=== 3. Providers (Newznab, Torznab) ==="
curl -s "${LL_API}&cmd=addProvider&type=newznab&name=NZBgeek&host=http%3A%2F%2F192.168.0.136%3A9696%2F5%2Fapi&api=${PROWLARR_KEY}&enabled=1&dispname=NZBgeek" -o /dev/null
curl -s "${LL_API}&cmd=addProvider&type=newznab&name=NzbPlanet&host=http%3A%2F%2F192.168.0.136%3A9696%2F6%2Fapi&api=${PROWLARR_KEY}&enabled=1&dispname=NzbPlanet" -o /dev/null
curl -s "${LL_API}&cmd=addProvider&type=torznab&name=LimeTorrents&host=http%3A%2F%2F192.168.0.136%3A9696%2F2%2Fapi&api=${PROWLARR_KEY}&enabled=1&dispname=LimeTorrents" -o /dev/null
echo "  NZBgeek, NzbPlanet, LimeTorrents added (Prowlarr indexers 5, 6, 2)"

# 4. qBittorrent download client
echo ""
echo "=== 4. qBittorrent ==="
wcfg "QBITTORRENT" "Config" "1"
wcfg "QBITTORRENT_HOST" "Config" "192.168.0.136"
wcfg "QBITTORRENT_PORT" "Config" "8080"
wcfg "QBITTORRENT_USER" "Config" "admin"
wcfg "QBITTORRENT_PASS" "Config" "$QB_PASS"
wcfg "QBITTORRENT_LABEL" "Config" "lazylibrarian"
echo "  qBittorrent: 192.168.0.136:8080, category lazylibrarian"

# 5. rdt-client (qBittorrent-compatible) - LazyLibrarian typically has one qBittorrent slot.
# If rdt-client is preferred, configure it instead. For now we use qBittorrent.
# User can add rdt-client manually in UI if both are desired.

# 6. Sabnzbd
echo ""
echo "=== 5. Sabnzbd ==="
if [ -n "${SABNZBD_API_KEY:-}" ]; then
  wcfg "SAB_HOST" "Config" "192.168.0.136"
  wcfg "SAB_PORT" "Config" "8085"
  wcfg "SAB_APIKEY" "Config" "$SABNZBD_API_KEY"
  wcfg "SAB_CATEGORY" "Config" "lazylibrarian"
  wcfg "SABNZBD" "Config" "1"
  echo "  Sabnzbd: 192.168.0.136:8085, category lazylibrarian"
  echo "  Add lazylibrarian category in Sabnzbd: Config → Categories"
else
  echo "  Set SABNZBD_API_KEY in .env to automate Sabnzbd"
fi

# 7. Custom notification (jellyfin-autoscan)
echo ""
echo "=== 6. Notifications ==="
wcfg "NOTIFY_CUSTOM" "Config" "1"
wcfg "NOTIFY_CUSTOM_ON_snatch" "Config" "0"
wcfg "NOTIFY_CUSTOM_ON_download" "Config" "1"
wcfg "NOTIFY_CUSTOM_SCRIPT" "Config" "/config/jellyfin-autoscan-notify.sh"
echo "  Custom script on download: /config/jellyfin-autoscan-notify.sh"

# 8. Reload config
echo ""
echo "=== 7. Reload config ==="
curl -s "${LL_API}&cmd=loadCFG" -o /dev/null
echo "  Config reloaded"

# 9. qBittorrent: add lazylibrarian category
echo ""
echo "=== 8. qBittorrent category ==="
tmp=$(mktemp)
curl -s -c "$tmp" -b "$tmp" -X POST "$BASE:8080/api/v2/auth/login" \
  -H "Referer: $BASE:8080" -d "username=admin&password=$QB_PASS" -o /dev/null 2>/dev/null || true
create_resp=$(curl -s -b "$tmp" -X POST "$BASE:8080/api/v2/torrents/createCategory" \
  -H "Referer: $BASE:8080" -d "category=lazylibrarian&savePath=" 2>/dev/null)
rm -f "$tmp"
if [ -z "$create_resp" ] || echo "$create_resp" | grep -qi "ok\|{}"; then
  echo "  lazylibrarian category added"
else
  echo "  (may already exist)"
fi

# 10. Jellyfin: Books and Audiobooks libraries
echo ""
echo "=== 9. Jellyfin libraries ==="
if [ -n "${JELLYFIN_API_KEY:-}" ]; then
  libs=$(curl -s "$BASE:8096/Library/VirtualFolders" -H "X-Emby-Token: $JELLYFIN_API_KEY" 2>/dev/null)
  has_books=$(echo "$libs" | python3 -c "import json,sys; d=json.load(sys.stdin); print(any(l.get('Name')=='Books' for l in d))" 2>/dev/null || echo "False")
  has_audio=$(echo "$libs" | python3 -c "import json,sys; d=json.load(sys.stdin); print(any(l.get('Name')=='Audiobooks' for l in d))" 2>/dev/null || echo "False")
  if [ "$has_books" = "True" ]; then
    echo "  Books library exists"
  else
    echo "  Adding Books library..."
    curl -s -X POST "$BASE:8096/Library/VirtualFolders" \
      -H "X-Emby-Token: $JELLYFIN_API_KEY" -H "Content-Type: application/json" \
      -d '{"Name":"Books","CollectionType":"books","LibraryOptions":{"PathInfos":[{"Path":"/media/books"}]}}' -o /dev/null && echo "  Added" || echo "  (add manually)"
  fi
  if [ "$has_audio" = "True" ]; then
    echo "  Audiobooks library exists"
  else
    echo "  Adding Audiobooks library..."
    curl -s -X POST "$BASE:8096/Library/VirtualFolders" \
      -H "X-Emby-Token: $JELLYFIN_API_KEY" -H "Content-Type: application/json" \
      -d '{"Name":"Audiobooks","CollectionType":"books","LibraryOptions":{"PathInfos":[{"Path":"/media/audiobooks"}]}}' -o /dev/null && echo "  Added" || echo "  (add manually)"
  fi
else
  echo "  Set JELLYFIN_API_KEY in .env to automate. Or add manually: Dashboard → Libraries"
fi

echo ""
echo "=== Done ==="
echo "LazyLibrarian: http://pi5.xcvr.link:5299"
echo "Remaining manual: Add rdt-client in Config → Torrent if desired; add lazylibrarian category in Sabnzbd."
echo "Prowlarr indexer IDs (5,6,2) may differ - check Prowlarr Indexers and update script if needed."

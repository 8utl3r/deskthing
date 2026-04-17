#!/bin/bash
# Sync Prowlarr indexers to *arr apps; optionally add Usenet indexers from .env
# Run from Mac: ./scripts/servarr-pi5-sync-and-usenet-indexers.sh
# Requires: scripts/servarr/.env (optional: NZBGEEK_API_KEY, NZBPLANET_API_KEY, etc.)

set -e
BASE="${PI_BASE:-http://192.168.0.136}"
PROWLARR_KEY="d1ad18607147432bb971559bcc32b888"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$DOTFILES_ROOT/scripts/servarr/.env"

add_indexer() {
  local name="$1"
  local base_url="$2"
  local api_key="$3"
  [ -z "$api_key" ] && return 1
  # Check if already added
  local existing
  existing=$(curl -s "$BASE:9696/api/v1/indexer" -H "X-Api-Key: $PROWLARR_KEY" | \
    python3 -c "import json,sys; d=json.load(sys.stdin); print(any(i.get('name')=='$name' for i in d))" 2>/dev/null || echo "False")
  [ "$existing" = "True" ] && echo "  $name: already exists" && return 1
  local resp
  resp=$(curl -s -X POST "$BASE:9696/api/v1/indexer" \
    -H "X-Api-Key: $PROWLARR_KEY" -H "Content-Type: application/json" \
    -d "{
      \"name\": \"$name\",
      \"implementation\": \"Newznab\",
      \"configContract\": \"NewznabSettings\",
      \"enable\": true,
      \"redirect\": true,
      \"appProfileId\": 1,
      \"priority\": 25,
      \"fields\": [
        {\"name\": \"baseUrl\", \"value\": \"$base_url\"},
        {\"name\": \"apiPath\", \"value\": \"/api\"},
        {\"name\": \"apiKey\", \"value\": \"$api_key\"}
      ],
      \"tags\": []
    }" 2>/dev/null)
  local id
  id=$(echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null)
  if [ -n "$id" ]; then
    echo "  $name: added (id=$id)"
    return 0
  else
    local err
    err=$(echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('message',d.get('errorMessage',''))[:80])" 2>/dev/null || echo "unknown")
    echo "  $name: failed - $err"
    return 1
  fi
}

sync_indexers() {
  echo "Triggering Prowlarr Sync App Indexers..."
  local resp
  resp=$(curl -s -X POST "$BASE:9696/api/v1/command" \
    -H "X-Api-Key: $PROWLARR_KEY" -H "Content-Type: application/json" \
    -d '{"name":"ApplicationIndexerSync"}' 2>/dev/null)
  local status
  status=$(echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('status',''))" 2>/dev/null)
  if [ "$status" = "started" ]; then
    echo "  Sync started successfully."
    return 0
  else
    echo "  Sync failed: $resp"
    return 1
  fi
}

echo "=== Prowlarr Sync + Usenet Indexers ==="
echo "Target: $BASE"
echo ""

# Load .env if present
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

added_any=0

# Add Usenet indexers if API keys are set
echo "Adding Usenet indexers (if API keys in .env)..."
add_indexer "NZBgeek" "https://api.nzbgeek.info" "${NZBGEEK_API_KEY:-}" && added_any=1 || true
add_indexer "NzbPlanet" "https://api.nzbplanet.net" "${NZBPLANET_API_KEY:-}" && added_any=1 || true
add_indexer "DrunkenSlug" "https://drunkenslug.com" "${DRUNKENSLUG_API_KEY:-}" && added_any=1 || true
add_indexer "NinjaCentral" "https://ninjacentral.co.za" "${NINJACENTRAL_API_KEY:-}" && added_any=1 || true

if [ $added_any -eq 0 ] && [ -z "${NZBGEEK_API_KEY:-}${NZBPLANET_API_KEY:-}${DRUNKENSLUG_API_KEY:-}${NINJACENTRAL_API_KEY:-}" ]; then
  echo "  (No Usenet API keys in .env - add NZBGEEK_API_KEY, NZBPLANET_API_KEY, etc. to enable)"
fi

echo ""
sync_indexers

if [ $added_any -eq 1 ]; then
  echo ""
  echo "Waiting 5s for sync to complete, then syncing again..."
  sleep 5
  sync_indexers
fi

echo ""
echo "Done. Prowlarr: $BASE:9696"

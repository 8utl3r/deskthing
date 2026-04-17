#!/bin/bash
# Remove Readarr from stack before/during LazyLibrarian migration
# Run from Mac: ./scripts/servarr-pi5-readarr-to-lazylibrarian-migration.sh
# Run this AFTER deploying LazyLibrarian (servarr-pi5-lazylibrarian-setup.sh)

set -e
BASE="${PI_BASE:-http://192.168.0.136}"
PROWLARR_KEY="d1ad18607147432bb971559bcc32b888"
PI="${PI_HOST:-pi@192.168.0.136}"

echo "=== Readarr → LazyLibrarian Migration ==="
echo "Target: $BASE"
echo ""

echo "=== 1. Remove Readarr from Prowlarr apps ==="
apps=$(curl -s "$BASE:9696/api/v1/applications" -H "X-Api-Key: $PROWLARR_KEY" 2>/dev/null)
readarr_id=$(echo "$apps" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for a in d:
    if a.get('name')=='Readarr':
        print(a['id'])
        break
" 2>/dev/null)
if [ -n "$readarr_id" ]; then
  echo "  Removing Readarr (id=$readarr_id) from Prowlarr..."
  curl -s -X DELETE "$BASE:9696/api/v1/applications/$readarr_id" -H "X-Api-Key: $PROWLARR_KEY" -o /dev/null
  echo "  Done"
else
  echo "  Readarr not found in Prowlarr (already removed?)"
fi

echo ""
echo "=== 2. Stop Readarr container/service ==="
ssh "$PI" 'bash -s' << 'REMOTE'
if command -v docker &>/dev/null; then
  sudo docker stop readarr 2>/dev/null && echo "  Stopped readarr container" || echo "  readarr container not running (or not Docker)"
  sudo docker rm readarr 2>/dev/null || true
elif systemctl is-active --quiet readarr 2>/dev/null; then
  sudo systemctl stop readarr && echo "  Stopped readarr service"
else
  echo "  readarr not found (Docker or systemd)"
fi
REMOTE

echo ""
echo "=== 3. Trigger Prowlarr sync (update indexers in remaining apps) ==="
curl -s -X POST "$BASE:9696/api/v1/command" \
  -H "X-Api-Key: $PROWLARR_KEY" -H "Content-Type: application/json" \
  -d '{"name":"ApplicationIndexerSync"}' 2>/dev/null | python3 -c "
import json,sys
d=json.load(sys.stdin)
print('  Sync started' if d.get('status')=='started' else '  Sync: '+str(d.get('message','')))
" 2>/dev/null || echo "  (Sync may need manual trigger in Prowlarr)"

echo ""
echo "=== Done ==="
echo "Readarr removed. LazyLibrarian handles books + audiobooks."
echo "Ensure LazyLibrarian is deployed: ./scripts/servarr-pi5-lazylibrarian-setup.sh"

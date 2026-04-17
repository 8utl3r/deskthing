#!/bin/bash
# Programmatic Jellyfin library deduplication: merge Real-Debrid into Movies/TV Shows,
# remove standalone Real-Debrid libraries. Idempotent - safe to run repeatedly.
#
# Run from Mac: ./scripts/servarr/jellyfin-dedupe-libraries.sh
# Automation: call from jellyfin-mount-fix.sh, or cron (e.g. daily 3am).
#
# API: POST /Library/VirtualFolders/Paths {"Name":"Movies","Path":"/media/realdebrid/movies"}
#      DELETE /Library/VirtualFolders?name=Real-Debrid%20Movies

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
BASE="${JELLYFIN_HOST:-http://192.168.0.136:8096}"

if [ ! -f "$ENV_FILE" ] || [ -z "$(grep -E '^JELLYFIN_API_KEY=' "$ENV_FILE" 2>/dev/null | cut -d= -f2)" ]; then
  echo "Error: $ENV_FILE must contain JELLYFIN_API_KEY"
  exit 1
fi

source "$ENV_FILE"
API="$BASE/Library/VirtualFolders"

# Fetch current libraries
LIBS=$(curl -s "$API" -H "X-Emby-Token: $JELLYFIN_API_KEY" 2>/dev/null)
if [ -z "$LIBS" ] || [ "$LIBS" = "[]" ]; then
  echo "Jellyfin API not reachable or no libraries. Skipping dedupe."
  exit 0
fi

CHANGED=0

# Check if Movies has RD path
MOVIES_HAS_RD=$(echo "$LIBS" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for x in d:
    if x.get('Name')=='Movies':
        locs = x.get('Locations', [])
        print('yes' if '/media/realdebrid/movies' in locs else 'no')
        break
else:
    print('no')
" 2>/dev/null || echo "no")

if [ "$MOVIES_HAS_RD" != "yes" ]; then
  echo "Adding /media/realdebrid/movies to Movies..."
  CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/Paths" \
    -H "X-Emby-Token: $JELLYFIN_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"Name":"Movies","Path":"/media/realdebrid/movies"}')
  [ "$CODE" = "204" ] && echo "  OK" && CHANGED=1 || echo "  Failed (HTTP $CODE)"
fi

# Check if TV Shows has RD path
TV_HAS_RD=$(echo "$LIBS" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for x in d:
    if x.get('Name')=='TV Shows':
        locs = x.get('Locations', [])
        print('yes' if '/media/realdebrid/shows' in locs else 'no')
        break
else:
    print('no')
" 2>/dev/null || echo "no")

if [ "$TV_HAS_RD" != "yes" ]; then
  echo "Adding /media/realdebrid/shows to TV Shows..."
  CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/Paths" \
    -H "X-Emby-Token: $JELLYFIN_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"Name":"TV Shows","Path":"/media/realdebrid/shows"}')
  [ "$CODE" = "204" ] && echo "  OK" && CHANGED=1 || echo "  Failed (HTTP $CODE)"
fi

# Remove standalone Real-Debrid libraries (VirtualFolders + orphaned Items)
# Jellyfin bug: DELETE VirtualFolders leaves orphaned collection items in DB; they still show in sidebar.
# We must also DELETE /Items/{id} to remove them from user Views.
RD_MOVIES_ID=$(echo "$LIBS" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for x in d:
    if x.get('Name')=='Real-Debrid Movies': print(x.get('ItemId','')); break
else: print('')
" 2>/dev/null || echo "")
RD_TV_ID=$(echo "$LIBS" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for x in d:
    if x.get('Name')=='Real-Debrid TV': print(x.get('ItemId','')); break
else: print('')
" 2>/dev/null || echo "")

# If not in VirtualFolders, check User Views for orphaned items (sidebar uses Views)
if [ -z "$RD_MOVIES_ID" ] || [ -z "$RD_TV_ID" ]; then
  USER_ID=$(curl -s "$BASE/Users" -H "X-Emby-Token: $JELLYFIN_API_KEY" 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d[0]['Id'] if d else '')" 2>/dev/null)
  if [ -n "$USER_ID" ]; then
    VIEWS=$(curl -s "$BASE/Users/$USER_ID/Views" -H "X-Emby-Token: $JELLYFIN_API_KEY" 2>/dev/null)
    [ -z "$RD_MOVIES_ID" ] && RD_MOVIES_ID=$(echo "$VIEWS" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for x in d.get('Items',[]):
    if x.get('Name')=='Real-Debrid Movies': print(x.get('Id','')); break
else: print('')
" 2>/dev/null || echo "")
    [ -z "$RD_TV_ID" ] && RD_TV_ID=$(echo "$VIEWS" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for x in d.get('Items',[]):
    if x.get('Name')=='Real-Debrid TV': print(x.get('Id','')); break
else: print('')
" 2>/dev/null || echo "")
  fi
fi

# Delete VirtualFolders (config) and Items (orphaned DB entries)
if [ -n "$RD_MOVIES_ID" ]; then
  echo "Removing Real-Debrid Movies..."
  curl -s -o /dev/null -X DELETE "$API?name=Real-Debrid%20Movies" -H "X-Emby-Token: $JELLYFIN_API_KEY"
  curl -s -o /dev/null -X DELETE "$BASE/Items/$RD_MOVIES_ID" -H "X-Emby-Token: $JELLYFIN_API_KEY"
  echo "  OK"
  CHANGED=1
fi
if [ -n "$RD_TV_ID" ]; then
  echo "Removing Real-Debrid TV..."
  curl -s -o /dev/null -X DELETE "$API?name=Real-Debrid%20TV" -H "X-Emby-Token: $JELLYFIN_API_KEY"
  curl -s -o /dev/null -X DELETE "$BASE/Items/$RD_TV_ID" -H "X-Emby-Token: $JELLYFIN_API_KEY"
  echo "  OK"
  CHANGED=1
fi

if [ $CHANGED -eq 1 ]; then
  echo "Triggering library refresh..."
  curl -s -o /dev/null -X POST "$BASE/Library/Refresh" -H "X-Emby-Token: $JELLYFIN_API_KEY"
fi

[ $CHANGED -eq 0 ] && echo "Libraries already deduped. Nothing to do." || echo "Done."

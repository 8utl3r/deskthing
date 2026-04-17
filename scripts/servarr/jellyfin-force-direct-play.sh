#!/bin/bash
# Disable transcoding for a Jellyfin user to force Direct Play (fixes video freeze on seek/skip)
# Run from Mac: ./scripts/servarr/jellyfin-force-direct-play.sh
# Optional: JF_USER=username (default: all non-admin users, or specify one)
# Requires: scripts/servarr/.env with JELLYFIN_API_KEY

set -e
BASE="${JF_BASE:-http://192.168.0.136:8096}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

[ -f "$ENV_FILE" ] || { echo "Missing $ENV_FILE"; exit 1; }
source "$ENV_FILE"
: "${JELLYFIN_API_KEY:?JELLYFIN_API_KEY not set}"

AUTH="X-Emby-Token: $JELLYFIN_API_KEY"
TARGET_USER="${JF_USER:-}"

echo "=== Jellyfin: Force Direct Play (disable transcoding) ==="
echo "Target: $BASE"
echo ""

# Get all users
USERS=$(curl -s -X GET "$BASE/Users" -H "$AUTH")
if [ -z "$USERS" ] || [ "$USERS" = "[]" ]; then
  echo "No users found or API error."
  exit 1
fi

# Extract user IDs and names
USER_IDS=($(echo "$USERS" | python3 -c "
import json,sys
for u in json.load(sys.stdin):
    print(u['Id'])
" 2>/dev/null))
USER_NAMES=($(echo "$USERS" | python3 -c "
import json,sys
for u in json.load(sys.stdin):
    print(u['Name'])
" 2>/dev/null))

UPDATED=0
for i in "${!USER_IDS[@]}"; do
  UID="${USER_IDS[$i]}"
  UNAME="${USER_NAMES[$i]}"
  if [ -n "$TARGET_USER" ] && [ "$UNAME" != "$TARGET_USER" ]; then
    continue
  fi
  # Skip admin if we're doing "all" (admin might need transcoding for admin tasks)
  if [ -z "$TARGET_USER" ] && [ "$UNAME" = "admin" ]; then
    echo "Skipping admin (use JF_USER=admin to include)"
    continue
  fi
  echo "Updating $UNAME ($UID)..."
  # Get current policy
  POLICY=$(curl -s -X GET "$BASE/Users/$UID" -H "$AUTH")
  if [ -z "$POLICY" ]; then
    echo "  Failed to get user"
    continue
  fi
  # Extract Policy object, preserve all fields, set transcoding to false
  NEW_POLICY=$(echo "$POLICY" | python3 -c "
import json,sys
d=json.load(sys.stdin)
p=d.get('Policy',{})
if not p:
    print('', file=sys.stderr)
    sys.exit(1)
p['EnableVideoPlaybackTranscoding']=False
p['EnableAudioPlaybackTranscoding']=False
print(json.dumps(p))
" 2>/dev/null)
  if [ -z "$NEW_POLICY" ]; then
    echo "  Failed to build policy"
    continue
  fi
  CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/Users/$UID/Policy" \
    -H "$AUTH" -H "Content-Type: application/json" -d "$NEW_POLICY")
  if [ "$CODE" = "200" ] || [ "$CODE" = "204" ]; then
    echo "  OK (HTTP $CODE)"
    UPDATED=$((UPDATED+1))
  else
    echo "  FAIL (HTTP $CODE) - response: $(curl -s -X POST "$BASE/Users/$UID/Policy" -H "$AUTH" -H "Content-Type: application/json" -d "$NEW_POLICY")"
  fi
done

echo ""
if [ $UPDATED -gt 0 ]; then
  echo "Done. Disabled transcoding for $UPDATED user(s). Playback will use Direct Play only."
  echo "If a client can't play the format, it won't play. Try a different client or re-enable transcoding in Dashboard."
else
  echo "No users updated. Use JF_USER=username to target a specific user."
fi

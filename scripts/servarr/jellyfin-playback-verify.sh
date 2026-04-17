#!/bin/bash
# Verify Jellyfin + Zurg playback: mount, file read, library status
# Run from Mac: ./scripts/servarr/jellyfin-playback-verify.sh
# Assume playback is failing until this script passes.

set -e
PI="${PI_HOST:-pi@192.168.0.136}"
BASE="http://192.168.0.136"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

FAILED=0

echo "=== Jellyfin playback verification ==="
echo "Target: $PI"
echo ""

# 1. Zurg reachable
echo "1. Zurg WebDAV (port 9999)..."
if ssh "$PI" "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:9999" 2>/dev/null | grep -qE '200|302'; then
  echo "   OK"
else
  echo "   FAIL - Zurg not responding"
  FAILED=1
fi

# 2. Mount exists and has content
echo "2. rclone mount (ls /mnt/zurg/movies)..."
MOUNT_COUNT=$(ssh "$PI" "ls /mnt/zurg/movies/ 2>/dev/null | head -5 | wc -l" 2>/dev/null || echo "0")
if [ "$MOUNT_COUNT" -gt 0 ]; then
  echo "   OK (found $MOUNT_COUNT entries)"
else
  echo "   FAIL - mount empty or not connected"
  FAILED=1
fi

# 3. File read test (small dd from first available file)
echo "3. File read (dd test from mount)..."
FIRST_FILE=$(ssh "$PI" "find /mnt/zurg/movies \\( -name '*.mkv' -o -name '*.mp4' \\) 2>/dev/null | head -1" 2>/dev/null)
if [ -n "$FIRST_FILE" ]; then
  READ_RESULT=$(ssh "$PI" "dd if='$FIRST_FILE' of=/dev/null bs=1M count=5 2>&1" 2>/dev/null)
  if echo "$READ_RESULT" | grep -qE "5\+?0? records in"; then
    echo "   OK (read 5MB from $(basename "$FIRST_FILE"))"
  else
    echo "   FAIL - dd error: $READ_RESULT"
    FAILED=1
  fi
else
  echo "   SKIP - no files in mount to test"
fi

# 4. Jellyfin API (if API key available)
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE" 2>/dev/null || true
  if [ -n "$JELLYFIN_API_KEY" ]; then
    echo "4. Jellyfin API (library count)..."
    LIBRARIES=$(curl -s -X GET "$BASE:8096/Library/VirtualFolders" -H "X-Emby-Token: $JELLYFIN_API_KEY" 2>/dev/null)
    if [ -n "$LIBRARIES" ]; then
      echo "   OK (API reachable)"
    else
      echo "   FAIL - Jellyfin API not reachable"
      FAILED=1
    fi
  else
    echo "4. Jellyfin API (skipped - no JELLYFIN_API_KEY in .env)"
  fi
else
  echo "4. Jellyfin API (skipped - no .env)"
fi

echo ""
if [ $FAILED -eq 0 ]; then
  echo "Verification PASSED. Try playback in Jellyfin."
  echo "If playback still fails: run ./scripts/servarr/zurg-rclone-playback-fix.sh"
else
  echo "Verification FAILED. Run fixes in order:"
  echo "  1. ./scripts/servarr/jellyfin-mount-fix.sh  (if mount empty)"
  echo "  2. ./scripts/servarr/zurg-rclone-playback-fix.sh  (if read fails)"
  echo "  3. ./scripts/servarr/jellyfin-playback-verify.sh  (re-run this)"
fi

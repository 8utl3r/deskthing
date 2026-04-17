#!/bin/bash
# Fix Jellyfin "Transport endpoint is not connected" - cleanup stale mount, restart rclone, then Jellyfin
# Run from Mac when local/Real-Debrid libraries show empty: ./scripts/servarr/jellyfin-mount-fix.sh
# Based on: rclone forum (fusermount -uz for stale mounts), Unraid guide (start order)

set -e
PI="${PI_HOST:-pi@192.168.0.136}"

echo "=== Jellyfin mount fix ==="
echo "Cleaning stale mount (if any), restarting rclone, then Jellyfin..."
echo ""

# Stop rclone, clean stale FUSE mount (per rclone forum), then start fresh
ssh "$PI" "sudo docker stop rclone-zurg 2>/dev/null || true; sleep 2"
ssh "$PI" "fusermount -uz /mnt/zurg 2>/dev/null || true"
ssh "$PI" "sudo docker start rclone-zurg"
echo "Waiting for rclone mount to stabilize..."
sleep 10

ssh "$PI" "ls /mnt/zurg/movies/ 2>&1 | head -1" || { echo "Mount failed"; exit 1; }

ssh "$PI" "sudo docker restart jellyfin"
echo "Waiting for Jellyfin to start..."
sleep 15

echo ""
echo "Triggering library scan..."
cd "$(dirname "$0")/../.." && source scripts/servarr/.env 2>/dev/null && \
  curl -s -X POST "http://192.168.0.136:8096/Library/Refresh" -H "X-Emby-Token: $JELLYFIN_API_KEY" >/dev/null

echo ""
echo "Ensuring library deduplication (RD merged into Movies/TV)..."
bash "$(dirname "$0")/jellyfin-dedupe-libraries.sh" 2>/dev/null || true

echo ""
echo "Done. Jellyfin: http://pi5.xcvr.link:8096"
echo "Scan runs in background; Movies and TV Shows (with RD) should populate within a minute."

#!/bin/bash
# Fix rclone mount for Jellyfin playback - resolves "Input/output error" when reading files
# Run from Mac: ./scripts/servarr/zurg-rclone-playback-fix.sh
# Root cause: rclone FUSE mount needed vfs-read-ahead and cache volume for WebDAV streaming

set -e
PI="${PI_HOST:-pi@192.168.0.136}"

echo "=== Zurg rclone playback fix ==="
echo "Target: $PI"
echo ""

# Stop rclone, keep zurg running
ssh "$PI" "sudo docker stop rclone-zurg 2>/dev/null || true; sudo docker rm rclone-zurg 2>/dev/null || true"
ssh "$PI" "sudo mkdir -p /mnt/data/appdata/rclone-cache"

# Get network name for zurg (rclone must reach zurg:9999)
NET_NAME=$(ssh "$PI" "sudo docker inspect zurg --format '{{range \$k, \$v := .NetworkSettings.Networks}}{{\$k}}{{end}}' 2>/dev/null")
if [ -z "$NET_NAME" ]; then
  NET_NAME="zurg-net"
fi
echo "Using network: $NET_NAME"

echo "Recreating rclone with improved mount options..."

# Recreate rclone with vfs-read-ahead, cache dir, buffer-size for streaming
ssh "$PI" "sudo docker run -d --name rclone-zurg --restart unless-stopped \
  --network $NET_NAME \
  -e TZ=America/Chicago \
  -e RCLONE_CACHE_DIR=/cache \
  -v /mnt/zurg:/data:rshared \
  -v /mnt/data/appdata/zurg/rclone.conf:/config/rclone/rclone.conf:ro \
  -v /mnt/data/appdata/rclone-cache:/cache \
  --cap-add SYS_ADMIN \
  --security-opt apparmor:unconfined \
  --device /dev/fuse:/dev/fuse \
  rclone/rclone:latest \
  mount zurg: /data \
  --allow-other \
  --allow-non-empty \
  --dir-cache-time 24h \
  --vfs-cache-mode full \
  --vfs-read-chunk-size 64M \
  --vfs-read-ahead 512M \
  --vfs-cache-max-size 20G \
  --buffer-size 256M"

echo ""
echo "Waiting for mount to stabilize..."
sleep 5

echo "Testing file read..."
ssh "$PI" "dd if='/mnt/zurg/movies/Cunk On Life (2024) [2160p] [4K] [WEB] [5.1] [YTS.MX]/Cunk.On.Life.2024.2160p.4K.WEB.x265.10bit.AAC5.1-[YTS.MX].mkv' of=/dev/null bs=1M count=10 2>&1" || true

echo ""
echo "Done. Try playing in Jellyfin again."
echo "If still failing, try a 1080p title (4K HEVC transcoding is heavy on Pi 5)."

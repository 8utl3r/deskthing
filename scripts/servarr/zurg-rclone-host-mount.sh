#!/bin/bash
# Run rclone on host instead of Docker - maximum stability (per Unraid guide)
# Use when Docker FUSE propagation causes "Transport endpoint" or scan failures.
# Prereqs: Zurg running (Docker), rclone installed on Pi, rclone.conf with url=http://127.0.0.1:9999/dav
# Run from Mac: ./scripts/servarr/zurg-rclone-host-mount.sh

set -e
PI="${PI_HOST:-pi@192.168.0.136}"

echo "=== Zurg rclone host mount (alternative to Docker) ==="
echo "Target: $PI"
echo ""

# Ensure rclone.conf exists with host URL (not zurg: from Docker network)
ssh "$PI" 'bash -s' << 'REMOTE'
set -e
CONF="/mnt/data/appdata/zurg/rclone.conf"
mkdir -p "$(dirname "$CONF")"
if [ ! -f "$CONF" ]; then
  echo "Creating $CONF with url=http://127.0.0.1:9999/dav"
  cat > "$CONF" << 'RCLONE'
[zurg]
type = webdav
url = http://127.0.0.1:9999/dav
vendor = other
pacer_min_sleep = 0
RCLONE
fi
# Ensure url points to host (not Docker network name)
grep -q "127.0.0.1:9999" "$CONF" || sed -i 's|url = .*|url = http://127.0.0.1:9999/dav|' "$CONF"
REMOTE

# Stop Docker rclone if running
ssh "$PI" "sudo docker stop rclone-zurg 2>/dev/null || true; sudo docker rm rclone-zurg 2>/dev/null || true"
ssh "$PI" "fusermount -uz /mnt/zurg 2>/dev/null || true"

# Install rclone if needed
ssh "$PI" "sudo apt-get install -y rclone fuse 2>/dev/null || true"

# Create mount script and systemd service
ssh "$PI" 'bash -s' << 'SERVICE'
set -e
mkdir -p /mnt/zurg /mnt/data/appdata/rclone-cache
cat > /tmp/zurg-mount.sh << 'MOUNT'
#!/bin/bash
# Wait for Zurg to be up
for i in $(seq 1 30); do
  curl -s -o /dev/null http://127.0.0.1:9999 && break
  sleep 2
done
rclone mount zurg: /mnt/zurg \
  --config=/mnt/data/appdata/zurg/rclone.conf \
  --allow-other --allow-non-empty \
  --dir-cache-time 20s \
  --vfs-cache-mode full \
  --vfs-cache-dir=/mnt/data/appdata/rclone-cache \
  --vfs-read-ahead 512M \
  --vfs-cache-max-size 20G \
  --vfs-read-chunk-size 64M \
  --buffer-size 256M \
  --daemon
MOUNT
chmod +x /tmp/zurg-mount.sh
sudo mv /tmp/zurg-mount.sh /usr/local/bin/zurg-mount.sh

# Systemd service
sudo tee /etc/systemd/system/rclone-zurg.service > /dev/null << 'UNIT'
[Unit]
Description=rclone mount for Zurg (Real-Debrid)
After=docker.service
Requires=docker.service

[Service]
Type=forking
ExecStart=/usr/local/bin/zurg-mount.sh
ExecStop=/usr/bin/fusermount -uz /mnt/zurg
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
UNIT
sudo systemctl daemon-reload
SERVICE

echo ""
echo "To enable and start:"
echo "  ssh $PI 'sudo systemctl enable rclone-zurg && sudo systemctl start rclone-zurg'"
echo ""
echo "Note: If you use docker-compose for Zurg, remove the rclone service from the compose"
echo "      so it doesn't conflict. Keep only the zurg container."
echo "Start order: Zurg (Docker) -> rclone (systemd) -> Jellyfin."

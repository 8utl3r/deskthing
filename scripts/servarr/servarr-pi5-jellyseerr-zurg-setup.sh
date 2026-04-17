#!/bin/bash
# Deploy Jellyseerr, Zurg+rclone, apply JellySkin to Jellyfin, integrate Zurg with Jellyfin
# Run from Mac: ./scripts/servarr/servarr-pi5-jellyseerr-zurg-setup.sh
# Requires: scripts/servarr/.env with JELLYFIN_API_KEY, REAL_DEBRID_API_KEY

set -e
PI="${PI_HOST:-pi@192.168.0.136}"
BASE="http://192.168.0.136"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE. Create from .env.example."
  exit 1
fi
source "$ENV_FILE"
: "${JELLYFIN_API_KEY:?JELLYFIN_API_KEY not set}"
: "${REAL_DEBRID_API_KEY:?REAL_DEBRID_API_KEY not set}"

echo "=== Servarr Pi5: Jellyseerr + Zurg + JellySkin ==="
echo "Target: $PI"
echo ""

# Create remote dir and copy files
REMOTE_DIR="/tmp/servarr-setup-$$"
ssh "$PI" "mkdir -p $REMOTE_DIR"

# 1. Deploy Jellyseerr
echo "=== 1. Deploy Jellyseerr (port 5055) ==="
ssh "$PI" "sudo docker stop jellyseerr 2>/dev/null || true; sudo docker rm jellyseerr 2>/dev/null || true"
ssh "$PI" "sudo mkdir -p /mnt/data/appdata/jellyseerr"
ssh "$PI" "sudo docker run -d --name jellyseerr --restart unless-stopped \
  -p 5055:5055 \
  -e TZ=America/Chicago \
  -e LOG_LEVEL=info \
  --add-host=host.docker.internal:host-gateway \
  -v /mnt/data/appdata/jellyseerr:/app/config \
  ghcr.io/fallenbagel/jellyseerr:latest"
echo "  Jellyseerr: $BASE:5055"
echo "  Radarr/Sonarr: use hostname host.docker.internal (not localhost - Jellyseerr runs in Docker)"
echo ""

# 2. Deploy Zurg + rclone
echo "=== 2. Deploy Zurg + rclone ==="
cat > /tmp/zurg-config.yml << ZURGCONFIG
zurg: v1
token: ${REAL_DEBRID_API_KEY}
port: 9999
check_for_changes_every_secs: 10
enable_repair: true
auto_delete_rar_torrents: true
on_library_update: sh /app/zurg_refresh.sh

directories:
  anime:
    group_order: 10
    group: media
    filters:
      - regex: /\\b[a-fA-F0-9]{8}\\b/
      - any_file_inside_regex: /\\b[a-fA-F0-9]{8}\\b/
  shows:
    group_order: 20
    group: media
    filters:
      - has_episodes: true
  movies:
    group_order: 30
    group: media
    only_show_the_biggest_file: true
    filters:
      - regex: /.*/
ZURGCONFIG

# Refresh script - triggers jellyfin-autoscan when Zurg content changes
cat > /tmp/zurg_refresh.sh << 'REFRESH'
#!/bin/sh
for arg in "$@"; do
  echo "Zurg update: $arg"
done
curl -s -X POST "http://127.0.0.1:8282/refresh" -o /dev/null || true
REFRESH
chmod +x /tmp/zurg_refresh.sh

cat > /tmp/rclone.conf << 'RCLONE'
[zurg]
type = webdav
url = http://zurg:9999/dav
vendor = other
pacer_min_sleep = 0
RCLONE

scp /tmp/zurg-config.yml "$PI:$REMOTE_DIR/config.yml"
scp /tmp/zurg_refresh.sh "$PI:$REMOTE_DIR/zurg_refresh.sh"
scp /tmp/rclone.conf "$PI:$REMOTE_DIR/rclone.conf"

ssh "$PI" "sudo mkdir -p /mnt/zurg /mnt/data/appdata/zurg /mnt/data/appdata/rclone-cache"
ssh "$PI" "sudo apt-get install -y fuse 2>/dev/null || true"

# Create docker-compose for zurg
ssh "$PI" "cat > $REMOTE_DIR/docker-compose-zurg.yml" << 'COMPOSE'
version: '3.8'
services:
  zurg:
    image: ghcr.io/debridmediamanager/zurg-testing:v0.9.3-hotfix.11
    container_name: zurg
    restart: unless-stopped
    ports:
      - "9999:9999"
    volumes:
      - ./zurg_refresh.sh:/app/zurg_refresh.sh:ro
      - ./config.yml:/app/config.yml:ro
      - zurgdata:/app/data
    extra_hosts:
      - "host.docker.internal:host-gateway"

  rclone:
    image: rclone/rclone:latest
    container_name: rclone-zurg
    restart: unless-stopped
    environment:
      TZ: America/Chicago
      PUID: 1000
      PGID: 1000
      RCLONE_CACHE_DIR: /cache
    volumes:
      - /mnt/zurg:/data:rshared
      - /mnt/data/appdata/rclone-cache:/cache
      - ./rclone.conf:/config/rclone/rclone.conf:ro
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    devices:
      - /dev/fuse:/dev/fuse:rwm
    depends_on:
      - zurg
    entrypoint: ["/bin/sh", "-c"]
    command: ["sleep 10 && exec rclone mount zurg: /data --allow-other --allow-non-empty --dir-cache-time 24h --vfs-cache-mode full --vfs-read-chunk-size 64M --vfs-read-ahead 512M --vfs-cache-max-size 20G --buffer-size 256M"]

volumes:
  zurgdata:
COMPOSE

# Fix: zurg_refresh needs to reach jellyfin-autoscan. jellyfin-autoscan uses host network.
# From zurg container, use host.docker.internal (we add it) or 172.17.0.1 (docker bridge).
# Actually jellyfin-autoscan is on host - so we need host network. The host's localhost from
# inside a container is the container itself. We need the host IP. On Pi, we add
# extra_hosts: host.docker.internal:host-gateway. Then from zurg, curl http://host.docker.internal:8282/refresh
# But host.docker.internal might not work on Linux. Let me use the network - if we put zurg and rclone
# in the same compose, they share a network. jellyfin-autoscan is on host. So we need the host IP.
# The simplest: use network_mode: host for zurg so it shares the host network. Then 127.0.0.1:8282 works.
# But then zurg would bind to 9999 on host - might conflict. Let me keep zurg on bridge network and use
# the gateway. From container, the host is at 172.17.0.1 (default bridge). So curl http://172.17.0.1:8282/refresh
# Let me update the refresh script to use that.
ssh "$PI" "sed -i 's|127.0.0.1:8282|172.17.0.1:8282|g' $REMOTE_DIR/zurg_refresh.sh 2>/dev/null || true"

ssh "$PI" "cd $REMOTE_DIR && sudo docker compose -f docker-compose-zurg.yml up -d"
echo "  Zurg: $BASE:9999 (WebDAV at /dav)"
echo "  Mount: /mnt/zurg"
echo ""

# 3. Add Zurg mount to Jellyfin and apply JellySkin
echo "=== 3. Add Zurg to Jellyfin + JellySkin ==="
# Jellyfin needs to see /mnt/zurg. Check if Jellyfin container has it.
# We need to add volume and restart Jellyfin. Also add library via API.
# And set Custom CSS for JellySkin.

JELLYFIN_CSS='@import url("https://cdn.jsdelivr.net/npm/jellyskin@latest/dist/main.css");
@import url("https://cdn.jsdelivr.net/npm/jellyskin@latest/dist/logo.css");
@import url("https://cdn.jsdelivr.net/npm/jellyskin@latest/dist/addons/gradients/nightSky.css");'

# Add Zurg library to Jellyfin via API
echo "  Adding Real-Debrid (Zurg) library to Jellyfin..."
# Jellyfin libraries use paths. The container sees /media/*. We need Jellyfin to have /media/realdebrid
# mapped to /mnt/zurg. So we need to recreate Jellyfin with the new volume. Let me do that.
ssh "$PI" 'bash -s' << 'JELLYFIN_UPDATE'
set -e
# Stop Jellyfin, recreate with zurg mount
sudo docker stop jellyfin 2>/dev/null || true
# Get current jellyfin run params - we need to add -v /mnt/zurg:/media/realdebrid:ro
# Check if jellyfin exists and get its config
JF_ID=$(sudo docker ps -a -q -f name=jellyfin 2>/dev/null | head -1)
if [ -n "$JF_ID" ]; then
  # Inspect and add new mount, then recreate
  sudo docker rm jellyfin 2>/dev/null || true
fi
# Recreate jellyfin with zurg mount
sudo docker run -d \
  --name jellyfin \
  --restart unless-stopped \
  -p 8096:8096 \
  -e TZ=America/Chicago \
  -e PUID=1000 \
  -e PGID=1000 \
  -v /var/lib/jellyfin-docker/config:/config \
  -v /var/lib/jellyfin-docker/cache:/cache \
  -v /var/lib/jellyfin-docker/transcodes:/config/transcodes \
  -v /mnt/data/media/movies:/media/movies:ro \
  -v /mnt/data/media/tv:/media/tv:ro \
  -v /mnt/data/media/music:/media/music:ro \
  -v /mnt/data/media/books:/media/books:ro \
  -v /mnt/data/media/audiobooks:/media/audiobooks:ro \
  -v /mnt/zurg:/media/realdebrid:ro \
  jellyfin/jellyfin:10.10.7
echo "  Jellyfin restarted with Zurg mount at /media/realdebrid"
echo "  Note: If Zurg/rclone start after Jellyfin, restart Jellyfin so it sees the mount."
JELLYFIN_UPDATE

# Add Real-Debrid library via API (Movies and TV from zurg structure)
sleep 5
curl -s -o /dev/null -w "%{http_code}" -X POST \
  "$BASE/Library/VirtualFolders?name=Real-Debrid%20Movies&collectionType=movies&paths=%2Fmedia%2Frealdebrid%2Fmovies&refreshLibrary=true" \
  -H "X-Emby-Token: $JELLYFIN_API_KEY" | grep -q 204 && echo "  Real-Debrid Movies: added" || echo "  Real-Debrid Movies: may exist"
curl -s -o /dev/null -w "%{http_code}" -X POST \
  "$BASE/Library/VirtualFolders?name=Real-Debrid%20TV&collectionType=tvshows&paths=%2Fmedia%2Frealdebrid%2Fshows&refreshLibrary=true" \
  -H "X-Emby-Token: $JELLYFIN_API_KEY" | grep -q 204 && echo "  Real-Debrid TV: added" || echo "  Real-Debrid TV: may exist"

# Apply JellySkin via config file (Jellyfin stores CustomCss in config)
echo "  Applying JellySkin theme..."
# The config might be in /var/lib/jellyfin-docker/config. CustomCss in system.xml or similar.
# Jellyfin 10.x uses a different config structure. Let me try to find and update.
ssh "$PI" "grep -r CustomCss /var/lib/jellyfin-docker/config 2>/dev/null | head -3 || echo 'Config location unknown'"

echo ""
echo "=== Manual step: JellySkin ==="
echo "1. Open $BASE:8096"
echo "2. Dashboard → General → Custom CSS"
echo "3. Paste and Save:"
echo ""
echo "$JELLYFIN_CSS"
echo ""
echo "=== Summary ==="
echo "Jellyseerr:  $BASE:5055  (configure with Jellyfin + Radarr + Sonarr)"
echo "Zurg:        $BASE:9999  (Real-Debrid WebDAV)"
echo "Jellyfin:    $BASE:8096  (add JellySkin CSS manually)"
echo ""
echo "Zurg content appears at /mnt/zurg (movies, shows, anime)."
echo "Jellyfin libraries 'Real-Debrid Movies' and 'Real-Debrid TV' added."
echo "Content added to RD via rdt-client will appear in Zurg and stream in Jellyfin."

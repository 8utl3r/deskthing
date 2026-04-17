#!/bin/bash
# Deploy LazyLibrarian (ebooks + audiobooks) and configure jellyfin-autoscan webhook
# Run from Mac: ./scripts/servarr-pi5-lazylibrarian-setup.sh
# Requires: scripts/servarr/.env with JELLYFIN_API_KEY (for custom notification script)
# After deploy: open http://pi5.xcvr.link:5299, add Prowlarr (Newznab), qBittorrent, Sabnzbd/rdt-client

set -e
PI="${PI_HOST:-pi@192.168.0.136}"
BASE="http://192.168.0.136"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$DOTFILES_ROOT/scripts/servarr/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE. Create from scripts/servarr/.env.example."
  exit 1
fi

echo "=== Deploy LazyLibrarian on Pi ==="
echo "Target: $PI"
echo ""

ssh "$PI" 'bash -s' << REMOTE_SCRIPT
set -e
BASE_APP="/mnt/data/appdata/lazylibrarian"
BASE_DL="/mnt/data/downloads"
sudo mkdir -p "\$BASE_APP" "\$BASE_DL/sabnzbd/complete/lazylibrarian" "\$BASE_DL/rdt-client/lazylibrarian"
sudo chown -R 1000:1000 "\$BASE_APP" "\$BASE_DL" 2>/dev/null || sudo chown -R pi:pi "\$BASE_APP" "\$BASE_DL"

# Stop existing
sudo docker stop lazylibrarian 2>/dev/null || true
sudo docker rm lazylibrarian 2>/dev/null || true

# Deploy LazyLibrarian
# - Downloads: sabnzbd and rdt-client category folders mounted so LL can process completed files
# - Books/audiobooks: media folders for final library
sudo docker run -d \
  --name lazylibrarian \
  -p 5299:5299 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/Chicago \
  -v "\$BASE_APP:/config" \
  -v "\$BASE_DL/sabnzbd/complete/lazylibrarian:/downloads/sabnzbd:rw" \
  -v "\$BASE_DL/rdt-client/lazylibrarian:/downloads/rdt:rw" \
  -v "/mnt/data/media/books:/books:rw" \
  -v "/mnt/data/media/audiobooks:/audiobooks:rw" \
  --restart unless-stopped \
  lscr.io/linuxserver/lazylibrarian:latest

echo "Waiting for config to initialize..."
sleep 10

# Create custom notification script for jellyfin-autoscan
mkdir -p "\$BASE_APP"
cat > "\$BASE_APP/jellyfin-autoscan-notify.sh" << 'NOTIFY_EOF'
#!/bin/bash
curl -s -X POST http://192.168.0.136:8282/refresh -o /dev/null || true
NOTIFY_EOF
chmod +x "\$BASE_APP/jellyfin-autoscan-notify.sh"
REMOTE_SCRIPT

echo ""
echo "=== Add lazylibrarian category to rdt-client ==="
ssh "$PI" 'bash -s' << 'RDT_SCRIPT'
DB="/mnt/data/downloads/rdt-client/db/rdtclient.db"
[ -f "$DB" ] && sqlite3 "$DB" "UPDATE Settings SET Value='radarr, sonarr, lidarr, lazylibrarian' WHERE SettingId='General:Categories';" && echo "  Updated rdt-client categories" || echo "  rdt-client db not found or already updated"
RDT_SCRIPT

echo ""
echo "=== Done ==="
echo "LazyLibrarian: http://pi5.xcvr.link:5299"
echo ""
echo "Next steps (in LazyLibrarian UI):"
echo "  1. Config → Ebook: Ebook folder = /books, formats = epub,mobi,pdf"
echo "  2. Config → Audio: Audio folder = /audiobooks, formats = mp3,m4b"
echo "  3. Config → Magazines: Disable unless needed"
echo "  4. Config → Newznab: Add Prowlarr - URL http://192.168.0.136:9696/1/api (or each indexer from Prowlarr), API key from Prowlarr Settings"
echo "  5. Config → Torrent: Add qBittorrent (host, port 8080, admin/pass, category lazylibrarian)"
echo "  6. Config → Torrent: Add rdt-client as second client (host 127.0.0.1, port 6500, category lazylibrarian)"
echo "  7. Config → Sabnzbd: Add Sabnzbd (host, port 8085, category lazylibrarian)"
echo "  8. Config → Notifications: Enable Custom, Notify on Download, script = /config/jellyfin-autoscan-notify.sh"
echo ""
echo "Sabnzbd: Add category lazylibrarian -> /downloads/complete/lazylibrarian"
echo "See: docs/services/servarr-audiobooks-ebooks-setup.md"

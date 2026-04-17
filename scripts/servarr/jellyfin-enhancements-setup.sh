#!/bin/bash
# Jellyfin enhancements: plugins, config, backup, NPM proxy
# Run from Mac: ./scripts/servarr/jellyfin-enhancements-setup.sh
# Requires: scripts/servarr/.env with JELLYFIN_API_KEY

set -e
PI="${PI_HOST:-pi@192.168.0.136}"
BASE="http://192.168.0.136:8096"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
JF_ABI="10.10.0.0"  # Jellyfin 10.10.7

[ -f "$ENV_FILE" ] || { echo "Missing $ENV_FILE"; exit 1; }
source "$ENV_FILE"
: "${JELLYFIN_API_KEY:?JELLYFIN_API_KEY not set}"

echo "=== Jellyfin Enhancements Setup ==="
echo "Target: $PI"
echo ""

# 1. Install plugins (download zip, extract to plugins dir on Pi)
echo "=== 1. Installing plugins ==="
PLUGINS_DIR="/var/lib/jellyfin-docker/config/plugins"
REMOTE_TMP="/tmp/jf-plugins-$$"
ssh "$PI" "mkdir -p $REMOTE_TMP"

# Official repo plugins for 10.10
install_plugin() {
  local name=$1 url=$2
  echo "  Installing $name..."
  ssh "$PI" "curl -sL -o $REMOTE_TMP/plugin.zip '$url' && sudo unzip -o -d $PLUGINS_DIR $REMOTE_TMP/plugin.zip 2>/dev/null && sudo chown -R 1000:1000 $PLUGINS_DIR"
}

install_plugin "Trakt" "https://repo.jellyfin.org/files/plugin/trakt/trakt_26.0.0.0.zip"
install_plugin "Reports" "https://repo.jellyfin.org/files/plugin/reports/reports_17.0.0.0.zip"
install_plugin "TMDb Box Sets" "https://repo.jellyfin.org/files/plugin/tmdb-box-sets/tmdb-box-sets_11.0.0.0.zip"
install_plugin "TheTVDB" "https://repo.jellyfin.org/files/plugin/thetvdb/thetvdb_16.0.0.0.zip"
install_plugin "Fanart" "https://repo.jellyfin.org/files/plugin/fanart/fanart_12.0.0.0.zip"

# Intro Skipper - from community repo (check compatibility)
# Intro Skipper manifest: https://intro-skipper.org/manifest.json - requires repo add in Dashboard
echo "  Intro Skipper: Add repo https://intro-skipper.org/manifest.json in Dashboard → Plugins → Repositories, then install"

ssh "$PI" "rm -rf $REMOTE_TMP"
echo ""

# 2. Playback (Direct Play is default; quality set per-user in Dashboard)
echo "=== 2. Playback & quality ==="
echo "  Direct Play: default (preferred on Pi 5). Per-user bitrate: Dashboard → Users → Playback"
echo ""

# 3. Scheduled scans (default: every 12h - keep as is)
echo "=== 3. Scheduled scans ==="
echo "  Default: Scan Media Library every 12 hours (keep)"
echo ""

# 4. Backup script
echo "=== 4. Backup script ==="
ssh "$PI" 'sudo tee /usr/local/bin/jellyfin-backup.sh > /dev/null << "BACKUP"
#!/bin/bash
# Backup Jellyfin config to /mnt/data/backups/jellyfin (or /tmp if no data)
BACKUP_ROOT="${JELLYFIN_BACKUP_ROOT:-/mnt/data/backups/jellyfin}"
mkdir -p "$BACKUP_ROOT" 2>/dev/null || { BACKUP_ROOT="/tmp/jellyfin-backups"; mkdir -p "$BACKUP_ROOT"; }
STAMP=$(date +%Y%m%d-%H%M)
tar -czf "$BACKUP_ROOT/jellyfin-config-$STAMP.tar.gz" -C /var/lib/jellyfin-docker config 2>/dev/null || true
# Keep last 7 days
find "$BACKUP_ROOT" -name "jellyfin-config-*.tar.gz" -mtime +7 -delete 2>/dev/null || true
BACKUP'
ssh "$PI" "sudo chmod +x /usr/local/bin/jellyfin-backup.sh"
echo "  Created /usr/local/bin/jellyfin-backup.sh (keeps 7 days)"
echo "  Run manually or add to cron: 0 3 * * * /usr/local/bin/jellyfin-backup.sh"
echo ""

# 5. NPM reverse proxy (verify)
echo "=== 5. Reverse proxy ==="
echo "  jellyfin.xcvr.link → 192.168.0.136:8096 (already in NPM)"
echo "  To re-add: ./scripts/npm/npm-api.sh add-jellyfin"
echo ""

# 6. Restart Jellyfin to load plugins
echo "=== 6. Restarting Jellyfin ==="
ssh "$PI" "sudo docker restart jellyfin"
echo "  Jellyfin restarted"
echo ""

echo "=== Manual steps (Dashboard) ==="
echo "1. Intro Skipper: Dashboard → Plugins → Repositories → Add https://intro-skipper.org/manifest.json → Install Intro Skipper"
echo "2. Trakt: Dashboard → Plugins → Trakt → Configure → Sign in with Trakt"
echo "3. TMDB/TVDB: Dashboard → Libraries → [library] → Manage → Metadata fetchers (TMDB, TheTVDB should be enabled)"
echo "4. Artwork: Dashboard → Libraries → [library] → Manage → Image fetchers (add Fanart, reorder as needed)"
echo "5. Quality: Dashboard → Users → [user] → Playback → Internet streaming bitrate limit (e.g. 8 Mbps for remote)"
echo ""
echo "=== Done ==="

#!/usr/bin/env bash
# Copy NPM config and data into NPMplus data directory on TrueNAS.
# Run after installing NPMplus and before first start. Certs: mount NPM's
# certs as /etc/letsencrypt on first start so NPMplus can migrate them to /data.
# See: docs/truenas/npm-to-npmplus-migration.md

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/factorio/.env.nas" 2>/dev/null || true
TRUENAS_HOST="${TRUENAS_HOST:-192.168.0.158}"
TRUENAS_USER="${TRUENAS_USER:-truenas_admin}"
NPM_DATA="/mnt/.ix-apps/app_mounts/nginx-proxy-manager/data"
NPM_CERTS="/mnt/.ix-apps/app_mounts/nginx-proxy-manager/certs"

if [[ -z "${1:-}" ]]; then
  echo "Usage: $0 <target_data_path>" >&2
  echo "  target_data_path = NPMplus /data directory on NAS (e.g. /mnt/.ix-apps/app_mounts/nginx-proxy-manager-plus/data or /mnt/.ix-apps/app_mounts/npmplus/data)" >&2
  echo "" >&2
  echo "Example:" >&2
  echo "  $0 /mnt/.ix-apps/app_mounts/npmplus/data" >&2
  exit 1
fi
TARGET_DATA="$1"

echo "Copying NPM data to NPMplus..."
echo "  From: $NPM_DATA"
echo "  To:   $TARGET_DATA"
echo "  Host: $TRUENAS_USER@$TRUENAS_HOST"
echo ""

# Stop NPM container so data is not in use (optional but safer)
ssh "$TRUENAS_USER@$TRUENAS_HOST" "echo '${NAS_SUDO_PASSWORD:-}' | sudo -S docker stop ix-nginx-proxy-manager-npm-1 2>/dev/null || true"

# Copy data (proxy hosts, SQLite DB, nginx config)
ssh "$TRUENAS_USER@$TRUENAS_HOST" "echo '${NAS_SUDO_PASSWORD:-}' | sudo -S mkdir -p '$TARGET_DATA' && echo '${NAS_SUDO_PASSWORD:-}' | sudo -S rsync -a '$NPM_DATA/' '$TARGET_DATA/'"

echo "Done. Next:"
echo "  1. Start NPMplus with NPM certs mounted as /etc/letsencrypt (one time) so it can move certs into /data."
echo "  2. After first run, remove the /etc/letsencrypt mount and restart NPMplus."
echo "  See docs/truenas/npm-to-npmplus-migration.md for details."

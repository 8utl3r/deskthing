#!/usr/bin/env bash
# Start NPMplus container (no /etc/letsencrypt mount — use after migration).
# Requires: factorio/.env.nas with NAS_SUDO_PASSWORD
# See: docs/truenas/npm-to-npmplus-migration.md

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/factorio/.env.nas" 2>/dev/null || { echo "Missing factorio/.env.nas"; exit 1; }
TRUENAS_HOST="${TRUENAS_HOST:-192.168.0.158}"
TRUENAS_USER="${TRUENAS_USER:-truenas_admin}"
NPMPLUS_DATA="/mnt/.ix-apps/app_mounts/npmplus/data"

ssh "$TRUENAS_USER@$TRUENAS_HOST" "echo '$NAS_SUDO_PASSWORD' | sudo -S docker stop npmplus 2>/dev/null || true; \
  echo '$NAS_SUDO_PASSWORD' | sudo -S docker rm npmplus 2>/dev/null || true; \
  echo '$NAS_SUDO_PASSWORD' | sudo -S docker run -d \
  --name npmplus \
  --restart unless-stopped \
  -p 80:80 -p 443:443 -p 30020:81 \
  -v $NPMPLUS_DATA:/data \
  -e TZ=America/Chicago -e PUID=568 -e PGID=568 \
  zoeyvid/npmplus:latest"
echo "NPMplus started. Admin UI: http://$TRUENAS_HOST:30020"

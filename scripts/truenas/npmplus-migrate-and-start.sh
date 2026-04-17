#!/usr/bin/env bash
# One-time: stop NPM, copy its data into NPMplus, start NPMplus with NPM certs
# mounted so certs are migrated into /data. After first run, use npmplus-start.sh
# (no cert mount). Requires: factorio/.env.nas with NAS_SUDO_PASSWORD
# See: docs/truenas/npm-to-npmplus-migration.md

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/factorio/.env.nas" 2>/dev/null || { echo "Missing factorio/.env.nas"; exit 1; }
TRUENAS_HOST="${TRUENAS_HOST:-192.168.0.158}"
TRUENAS_USER="${TRUENAS_USER:-truenas_admin}"
NPM_DATA="/mnt/.ix-apps/app_mounts/nginx-proxy-manager/data"
NPM_CERTS="/mnt/.ix-apps/app_mounts/nginx-proxy-manager/certs"
NPMPLUS_DATA="/mnt/.ix-apps/app_mounts/npmplus/data"

echo "=== NPMplus one-time migration and first start ==="
echo "Host: $TRUENAS_USER@$TRUENAS_HOST"
echo ""

# 1. Stop NPM
echo "1. Stopping NPM..."
ssh "$TRUENAS_USER@$TRUENAS_HOST" "echo '$NAS_SUDO_PASSWORD' | sudo -S docker stop ix-nginx-proxy-manager-npm-1 2>/dev/null || true"
ssh "$TRUENAS_USER@$TRUENAS_HOST" "echo '$NAS_SUDO_PASSWORD' | sudo -S docker rm ix-nginx-proxy-manager-npm-1 2>/dev/null || true"
echo "   Done."
echo ""

# 2. Copy NPM data to NPMplus data dir
echo "2. Copying NPM data to $NPMPLUS_DATA ..."
ssh "$TRUENAS_USER@$TRUENAS_HOST" "echo '$NAS_SUDO_PASSWORD' | sudo -S mkdir -p '$NPMPLUS_DATA' && echo '$NAS_SUDO_PASSWORD' | sudo -S rsync -a '$NPM_DATA/' '$NPMPLUS_DATA/'"
echo "   Done."
echo ""

# 3. Stop any existing npmplus container, then start with cert mount (first run)
echo "3. Starting NPMplus (first run with /etc/letsencrypt mount for cert migration)..."
ssh "$TRUENAS_USER@$TRUENAS_HOST" "echo '$NAS_SUDO_PASSWORD' | sudo -S docker stop npmplus 2>/dev/null || true; \
  echo '$NAS_SUDO_PASSWORD' | sudo -S docker rm npmplus 2>/dev/null || true; \
  echo '$NAS_SUDO_PASSWORD' | sudo -S docker run -d \
  --name npmplus \
  --restart unless-stopped \
  -p 80:80 -p 443:443 -p 30020:81 \
  -v $NPMPLUS_DATA:/data \
  -v $NPM_CERTS:/etc/letsencrypt \
  -e TZ=America/Chicago -e PUID=568 -e PGID=568 \
  zoeyvid/npmplus:latest"
echo ""
echo "NPMplus is starting. Admin UI: http://$TRUENAS_HOST:30020"
echo ""
echo "After it has run once (certs migrated into /data), stop it and start without the cert mount:"
echo "  $REPO_ROOT/scripts/truenas/npmplus-start.sh"
echo "  (Or see docs/truenas/npm-to-npmplus-migration.md)"

#!/usr/bin/env bash
# Install and run NPMplus only (no migration). Stops NPM, creates data dir, starts NPMplus.
# First login: http://192.168.0.158:30020 — default is admin@example.org; password is in container logs on first start, or set INITIAL_ADMIN_PASSWORD below.
# Requires: factorio/.env.nas with NAS_SUDO_PASSWORD

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/factorio/.env.nas" 2>/dev/null || { echo "Missing factorio/.env.nas"; exit 1; }
TRUENAS_HOST="${TRUENAS_HOST:-192.168.0.158}"
TRUENAS_USER="${TRUENAS_USER:-truenas_admin}"
NPMPLUS_DATA="/mnt/.ix-apps/app_mounts/npmplus/data"

echo "=== NPMplus install (no migration) ==="
echo "Host: $TRUENAS_USER@$TRUENAS_HOST"
echo ""

echo "1. Stopping NPM to free ports 80, 443, 30020..."
ssh "$TRUENAS_USER@$TRUENAS_HOST" "echo '$NAS_SUDO_PASSWORD' | sudo -S docker stop ix-nginx-proxy-manager-npm-1 2>/dev/null || true"
ssh "$TRUENAS_USER@$TRUENAS_HOST" "echo '$NAS_SUDO_PASSWORD' | sudo -S docker rm ix-nginx-proxy-manager-npm-1 2>/dev/null || true"
echo "   Done."
echo ""

echo "2. Creating NPMplus data directory..."
ssh "$TRUENAS_USER@$TRUENAS_HOST" "echo '$NAS_SUDO_PASSWORD' | sudo -S mkdir -p $NPMPLUS_DATA"
echo "   Done."
echo ""

echo "3. Starting NPMplus..."
ssh "$TRUENAS_USER@$TRUENAS_HOST" "echo '$NAS_SUDO_PASSWORD' | sudo -S docker stop npmplus 2>/dev/null || true; \
  echo '$NAS_SUDO_PASSWORD' | sudo -S docker rm npmplus 2>/dev/null || true; \
  echo '$NAS_SUDO_PASSWORD' | sudo -S docker run -d \
  --name npmplus \
  --restart unless-stopped \
  -p 80:80 -p 443:443 -p 30020:81 \
  -v $NPMPLUS_DATA:/data \
  -e TZ=America/Chicago -e PUID=568 -e PGID=568 \
  zoeyvid/npmplus:latest"
echo ""
echo "NPMplus is installed and starting."
echo "  Admin UI: http://$TRUENAS_HOST:30020"
echo "  First login: admin@example.org — password is printed in container logs on first start."
echo "  To see it: ssh $TRUENAS_USER@$TRUENAS_HOST 'sudo docker logs npmplus 2>&1 | head -30'"
echo ""
echo "To copy your existing NPM config into NPMplus later, use: scripts/truenas/npmplus-migrate-and-start.sh (run after stopping this container and copying data)."

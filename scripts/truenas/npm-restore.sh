#!/usr/bin/env bash
# Restore NPM container on ports 80/443 (manual container, not ix-apps managed)
# Requires: factorio/.env.nas with NAS_SUDO_PASSWORD
# See: docs/truenas/npm-manual-container-recovery.md

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/factorio/.env.nas" 2>/dev/null || { echo "Missing factorio/.env.nas"; exit 1; }

ssh truenas_admin@192.168.0.158 "echo '$NAS_SUDO_PASSWORD' | sudo -S docker stop ix-nginx-proxy-manager-npm-1 2>/dev/null || true; \
  echo '$NAS_SUDO_PASSWORD' | sudo -S docker rm ix-nginx-proxy-manager-npm-1 2>/dev/null || true; \
  echo '$NAS_SUDO_PASSWORD' | sudo -S docker run -d \
  --name ix-nginx-proxy-manager-npm-1 \
  --restart unless-stopped \
  -p 80:80 -p 443:443 -p 30020:81 \
  -v /mnt/.ix-apps/app_mounts/nginx-proxy-manager/data:/data \
  -v /mnt/.ix-apps/app_mounts/nginx-proxy-manager/certs:/etc/letsencrypt \
  -e TZ=America/Chicago -e PUID=568 -e PGID=568 \
  jc21/nginx-proxy-manager:2.13.6"
echo "NPM restored. Admin UI: http://192.168.0.158:30020"

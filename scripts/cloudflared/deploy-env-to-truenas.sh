#!/usr/bin/env bash
# Copy cloudflared/.env to TrueNAS so the tunnel can read TUNNEL_TOKEN
# Requires: cloudflared/.env with TUNNEL_TOKEN
# Requires: factorio/.env.nas with NAS_SUDO_PASSWORD (for sudo mkdir/chmod)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_LOCAL="$REPO_ROOT/cloudflared/.env"
ENV_REMOTE="/mnt/tank/apps/cloudflared/.env"
NAS_HOST="${TRUENAS_HOST:-192.168.0.158}"
NAS_USER="${TRUENAS_USER:-truenas_admin}"

if [[ ! -f "$ENV_LOCAL" ]]; then
  echo "Error: $ENV_LOCAL not found. Copy from .env.example and add TUNNEL_TOKEN." >&2
  exit 1
fi

source "$REPO_ROOT/factorio/.env.nas" 2>/dev/null || true
: "${NAS_SUDO_PASSWORD:?Create factorio/.env.nas with NAS_SUDO_PASSWORD}"

echo "Deploying cloudflared/.env to $NAS_USER@$NAS_HOST:$ENV_REMOTE"

# Copy to temp, then move with sudo (preserves content, sets perms)
scp -q "$ENV_LOCAL" "$NAS_USER@$NAS_HOST:/tmp/cloudflared.env"
ssh "$NAS_USER@$NAS_HOST" "echo \"$NAS_SUDO_PASSWORD\" | sudo -S mkdir -p /mnt/tank/apps/cloudflared && \
  echo \"$NAS_SUDO_PASSWORD\" | sudo -S mv /tmp/cloudflared.env $ENV_REMOTE && \
  echo \"$NAS_SUDO_PASSWORD\" | sudo -S chmod 600 $ENV_REMOTE && \
  echo 'Done. Restart the cloudflared app if it is already running.'"

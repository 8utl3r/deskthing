#!/bin/bash
# Copy the full Caddyfile from dotfiles to the Pi 5 and restart Caddy.
# Run from Mac: ./scripts/servarr-pi5-caddy-update.sh
# Prerequisite: Caddy already deployed on Pi (e.g. via servarr-pi5-caddy-setup.sh).
#
# Caddyfile: scripts/servarr-pi5/caddy/Caddyfile

set -e
PI="${PI_HOST:-pi@192.168.0.136}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CADDYFILE_SRC="$DOTFILES_ROOT/scripts/servarr-pi5/caddy/Caddyfile"

if [[ ! -f "$CADDYFILE_SRC" ]]; then
  echo "Error: Caddyfile not found at $CADDYFILE_SRC"
  exit 1
fi

echo "=== Update Caddy on Pi 5 ==="
echo "Copying $CADDYFILE_SRC to $PI:/var/lib/caddy/config/Caddyfile"
scp "$CADDYFILE_SRC" "$PI:/tmp/Caddyfile"
ssh "$PI" 'sudo mv /tmp/Caddyfile /var/lib/caddy/config/Caddyfile && sudo docker restart caddy'
echo "Caddy restarted. Verify with: curl -sI -H \"Host: rules.xcvr.link\" http://192.168.0.136"
echo ""

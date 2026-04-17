#!/bin/bash
# Deploy Navidrome on Pi 5 for music (replaces Jellyfin Music)
# Run from Mac: ./scripts/servarr-pi5-navidrome-setup.sh
# Or on Pi: ./scripts/servarr-pi5-navidrome-setup.sh --local
#
# Prerequisites: /mnt/data/media/music exists (Lidarr root folder)
# After: Remove Music library from Jellyfin (see docs/services/servarr-pi5-navidrome-migration.md)

set -e
PI="${PI_HOST:-pi@192.168.0.136}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Deploy Navidrome on Pi 5 ==="
echo ""

if [[ " $* " = *" --local "* ]]; then
  echo "Running locally on Pi..."
  REMOTE_SCRIPT='
    set -e
    sudo mkdir -p /var/lib/navidrome
    sudo chown -R 1000:1000 /var/lib/navidrome
    
    sudo docker stop navidrome 2>/dev/null || true
    sudo docker rm navidrome 2>/dev/null || true
    
    sudo docker run -d \
      --name navidrome \
      --restart unless-stopped \
      -p 4533:4533 \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ=America/Los_Angeles \
      -e ND_SCANINTERVAL=1m \
      -v /var/lib/navidrome:/data \
      -v /mnt/data/media/music:/music:ro \
      deluan/navidrome:latest
    
    echo ""
    echo "Navidrome started. Waiting 5s..."
    sleep 5
    curl -s -o /dev/null -w "%{http_code}" http://localhost:4533 | grep -q 200 && echo "  OK: Navidrome responsive" || echo "  Warning: Navidrome may still be starting"
  '
  bash -c "$REMOTE_SCRIPT"
else
  echo "Deploying via SSH to $PI..."
  ssh "$PI" "bash -s" << 'REMOTE_SCRIPT'
    set -e
    sudo mkdir -p /var/lib/navidrome
    sudo chown -R 1000:1000 /var/lib/navidrome
    
    sudo docker stop navidrome 2>/dev/null || true
    sudo docker rm navidrome 2>/dev/null || true
    
    sudo docker run -d \
      --name navidrome \
      --restart unless-stopped \
      -p 4533:4533 \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ=America/Los_Angeles \
      -e ND_SCANINTERVAL=1m \
      -v /var/lib/navidrome:/data \
      -v /mnt/data/media/music:/music:ro \
      deluan/navidrome:latest
    
    echo ""
    echo "Navidrome started. Waiting 5s..."
    sleep 5
    curl -s -o /dev/null -w "%{http_code}" http://localhost:4533 | grep -q 200 && echo "  OK: Navidrome responsive" || echo "  Warning: Navidrome may still be starting"
REMOTE_SCRIPT
fi

echo ""
echo "=== Done ==="
echo "Navidrome: http://pi5.xcvr.link:4533 (or http://192.168.0.136:4533)"
echo ""
echo "Next steps:"
echo "  1. Open URL, create admin user (e.g. pete)"
echo "  2. Remove Music library from Jellyfin (Dashboard → Libraries → delete Music)"
echo "  3. Add music.xcvr.link or listen.xcvr.link → 4533 in NPM/Caddy"
echo "  4. Install Symfonium (Android) or Amperfy (iOS), connect to Navidrome"
echo ""
echo "See: docs/services/servarr-pi5-navidrome-migration.md"

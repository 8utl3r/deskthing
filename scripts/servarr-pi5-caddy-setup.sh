#!/bin/bash
# Deploy Caddy on Pi 5 as reverse proxy (Docker, no install – assumes Docker already present)
# Run from Mac: ./scripts/servarr-pi5-caddy-setup.sh
# Or on Pi: ./scripts/servarr-pi5-caddy-setup.sh --local
#
# Uses ports 80 and 443. Edit /var/lib/caddy/config/Caddyfile on the Pi after deploy.
# Example Caddyfile: scripts/servarr-pi5-caddyfile.example

set -e
PI="${PI_HOST:-pi@192.168.0.136}"

# Minimal Caddyfile: listen/watch/read.xcvr.link → Jellyfin. Replace domain if needed.
read -r -d '' CADDYFILE_CONTENT << 'CADDYFILE' || true
# listen, watch, read.xcvr.link → Jellyfin on Pi 5
listen.xcvr.link, watch.xcvr.link, read.xcvr.link {
	reverse_proxy localhost:8096
}
CADDYFILE

echo "=== Deploy Caddy on Pi 5 (Docker) ==="
echo ""

run_on_pi() {
  set -e
  if ! command -v docker &>/dev/null; then
    echo "Docker not found. Install Docker on the Pi first."
    exit 1
  fi

  sudo mkdir -p /var/lib/caddy/config /var/lib/caddy/data
  echo "$CADDYFILE_CONTENT" | sudo tee /var/lib/caddy/config/Caddyfile >/dev/null

  sudo docker stop caddy 2>/dev/null || true
  sudo docker rm caddy 2>/dev/null || true

  sudo docker run -d \
    --name caddy \
    --restart unless-stopped \
    -p 80:80 \
    -p 443:443 \
    -p 443:443/udp \
    -v /var/lib/caddy/config:/etc/caddy:ro \
    -v /var/lib/caddy/data:/data \
    caddy:latest

  echo ""
  echo "Caddy started. Waiting 3s..."
  sleep 3
  curl -s -o /dev/null -w "%{http_code}" http://localhost:80 2>/dev/null | grep -q 200 && echo "  OK: Caddy responsive on :80" || echo "  Note: Caddy may need DNS (e.g. listen.xcvr.link) for 200 on :80"
}

if [[ " $* " = *" --local "* ]]; then
  echo "Running locally on Pi..."
  CADDYFILE_CONTENT="$CADDYFILE_CONTENT" run_on_pi
else
  echo "Deploying via SSH to $PI..."
  export CADDYFILE_CONTENT
  ssh "$PI" 'bash -s' << 'REMOTE_SCRIPT'
    set -e
    if ! command -v docker &>/dev/null; then
      echo "Docker not found. Install Docker on the Pi first."
      exit 1
    fi

    sudo mkdir -p /var/lib/caddy/config /var/lib/caddy/data
    sudo tee /var/lib/caddy/config/Caddyfile << 'CADDYFILE'
# listen, watch, read.xcvr.link → Jellyfin on Pi 5
listen.xcvr.link, watch.xcvr.link, read.xcvr.link {
	reverse_proxy localhost:8096
}
CADDYFILE

    sudo docker stop caddy 2>/dev/null || true
    sudo docker rm caddy 2>/dev/null || true

    sudo docker run -d \
      --name caddy \
      --restart unless-stopped \
      -p 80:80 \
      -p 443:443 \
      -p 443:443/udp \
      -v /var/lib/caddy/config:/etc/caddy:ro \
      -v /var/lib/caddy/data:/data \
      caddy:latest

    echo ""
    echo "Caddy started. Waiting 3s..."
    sleep 3
    curl -s -o /dev/null -w "%{http_code}" http://localhost:80 2>/dev/null | grep -q 200 && echo "  OK: Caddy responsive on :80" || echo "  Note: Caddy may need DNS for 200 on :80"
REMOTE_SCRIPT
fi

echo ""
echo "=== Done ==="
echo "Caddy: http://pi5.xcvr.link (or https://listen.xcvr.link etc. once DNS points here)"
echo "Config on Pi: /var/lib/caddy/config/Caddyfile (edit and: sudo docker restart caddy)"
echo "Example Caddyfile: scripts/servarr-pi5-caddyfile.example"
echo ""

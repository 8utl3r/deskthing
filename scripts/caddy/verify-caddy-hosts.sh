#!/bin/bash
# Verify each Caddy proxy host (after NPM+ → Caddy on Pi 5 migration).
# Usage: ./scripts/caddy/verify-caddy-hosts.sh [BASE_URL]
# Default BASE_URL: http://192.168.0.136

set -e
BASE_URL="${1:-http://192.168.0.136}"

HOSTS=(
  sso.xcvr.link
  nas.xcvr.link
  headscale.xcvr.link
  rules.xcvr.link
  immich.xcvr.link
  n8n.xcvr.link
  syncthing.xcvr.link
  jellyfin.xcvr.link
  music.xcvr.link
  listen.xcvr.link
  watch.xcvr.link
  read.xcvr.link
)

echo "=== Caddy proxy host verification ==="
echo "Base URL: $BASE_URL"
echo ""

for host in "${HOSTS[@]}"; do
  code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 -H "Host: $host" "$BASE_URL" 2>/dev/null || echo "ERR")
  printf "  %-25s %s\n" "$host" "$code"
done

echo ""
echo "2xx/3xx = OK. 502 = backend unreachable. ERR = connection failed."

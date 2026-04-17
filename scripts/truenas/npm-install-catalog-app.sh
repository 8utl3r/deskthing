#!/usr/bin/env bash
# Try to install the catalog app "Nginx Proxy Manager" via TrueNAS API so the app
# is managed by TrueNAS (start/stop/upgrade in UI). Uses SSH + midclt.
# Requires: factorio/.env.nas with NAS_SUDO_PASSWORD
# See: docs/truenas/npm-truenas-managed.md

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/factorio/.env.nas" 2>/dev/null || { echo "Missing factorio/.env.nas"; exit 1; }
TRUENAS_HOST="${TRUENAS_HOST:-192.168.0.158}"
TRUENAS_USER="${TRUENAS_USER:-truenas_admin}"
APP_NAME="nginx-proxy-manager"
TRAIN="community"

run_nas() {
  local cmd="$1"
  printf '%s\n' "$cmd" | ssh "$TRUENAS_USER@$TRUENAS_HOST" "echo '${NAS_SUDO_PASSWORD}' | sudo -S bash -s"
}

echo "=== Install Nginx Proxy Manager (catalog app) for TrueNAS management ==="
echo "Host: $TRUENAS_USER@$TRUENAS_HOST"
echo ""

# Stop manual NPM container if running so ports are free
echo "1. Stopping any manual NPM container..."
run_nas 'docker stop ix-nginx-proxy-manager-npm-1 2>/dev/null || true; docker rm ix-nginx-proxy-manager-npm-1 2>/dev/null || true'
echo "   Done."
echo ""

# Try to install via API. Method name and payload vary by TrueNAS version (24.10 uses Docker apps).
echo "2. Installing app from catalog (this may take a minute)..."
# Try app.create (common pattern: name, train, version, values)
VALUES='{"TZ":"America/Chicago","run_as":{"user":568,"group":568},"network":{"web_port":{"bind_mode":"published","port_number":30020},"http_port":{"bind_mode":"published","port_number":80},"https_port":{"bind_mode":"published","port_number":443}}}'
OUT=$(run_nas "midclt call -j app.create '{\"name\": \"$APP_NAME\", \"train\": \"$TRAIN\", \"values\": $VALUES}' 2>&1") || true

if echo "$OUT" | grep -qE '"id"|"name"|"state"'; then
  echo "   App install started or completed. Check Apps → Installed in the TrueNAS UI."
  echo "   Admin UI: http://$TRUENAS_HOST:30020"
  exit 0
fi

# Try alternate: some versions use catalog.* or different create signature
if echo "$OUT" | grep -qi "not found\|does not exist\|invalid"; then
  echo "   API install not available or failed for this TrueNAS version."
  echo ""
  echo "Install via the TrueNAS UI:"
  echo "  1. Apps → Discover → search 'nginx-proxy-manager' → Install"
  echo "  2. Set WebUI Port 30020, HTTP 80, HTTPS 443"
  echo "  3. Save and start. Admin UI: http://$TRUENAS_HOST:30020"
  echo ""
  echo "See: docs/truenas/npm-truenas-managed.md"
  exit 1
fi

echo "$OUT"
echo ""
echo "If the app did not install, use the UI: Apps → Discover → nginx-proxy-manager → Install"
echo "See: docs/truenas/npm-truenas-managed.md"

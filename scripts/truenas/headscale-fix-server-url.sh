#!/usr/bin/env bash
# Fix Headscale Server URL on TrueNAS (192.168.1.158 -> 192.168.0.158)
# Run this on TrueNAS via SSH: bash headscale-fix-server-url.sh
#
# The wrong IP causes registration URLs to use 192.168.1.158, which doesn't
# load in the browser. This script updates the app config via midclt.

set -e

APP_NAME="headscale"
CORRECT_URL="http://192.168.0.158:30210"

echo "=== Headscale Server URL Fix ==="
echo "App: $APP_NAME"
echo "Correct URL: $CORRECT_URL"
echo ""

# Get current app config to inspect structure
echo "Fetching current app config..."
CONFIG=$(midclt call app.get_instance "$APP_NAME" 2>/dev/null || true)
if [ -z "$CONFIG" ]; then
  echo "ERROR: Could not get app config. Is the app named '$APP_NAME'?"
  echo "List apps with: midclt call app.query"
  exit 1
fi

# Try to update - the exact path depends on the app chart
# Common patterns: headscale.server_url, headscaleConfig.server_url, config.server_url
echo "Attempting to update Headscale Server URL..."

# Headscale app uses: values.headscale.server_url
# See: apps.truenas.com/catalog/headscale
echo "Updating server_url to $CORRECT_URL..."
if midclt call -j app.update "$APP_NAME" '{"values": {"headscale": {"server_url": "'"$CORRECT_URL"'"}}}' 2>/dev/null; then
  echo "Update submitted. The app may redeploy - wait for it to become healthy."
else
  echo "midclt update failed. Use the manual UI steps below."
fi

echo ""
echo "=== Manual fallback ==="
echo "If the script didn't work, update via TrueNAS UI:"
echo "  1. Apps → Installed → headscale → Edit"
echo "  2. Headscale Configuration → Headscale Server URL"
echo "  3. Set to: $CORRECT_URL"
echo "  4. Save (may redeploy the app)"
echo ""
echo "Then register your Mac node on TrueNAS:"
echo "  sudo docker exec ix-headscale-headscale-1 headscale nodes register --key <KEY> --user pete"
echo "  (Get <KEY> from: tailscale up --login-server $CORRECT_URL --accept-routes --reset --force-reauth)"

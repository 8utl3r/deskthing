#!/usr/bin/env bash
# Add xcvr.link DNS records to Headscale MagicDNS for seamless access (LAN + Tailscale)
# Run on TrueNAS via SSH. Creates extra-records.json and shows how to configure Headscale.
#
# After setup: immich.xcvr.link etc. resolve via Tailscale DNS (100.100.100.100)
# whether you're on LAN or remote.

set -e

RECORDS_PATH="/mnt/tank/apps/headscale/extra-records.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== Headscale xcvr.link DNS Setup ==="
echo ""

# Create directory and copy JSON
echo "1. Creating extra-records.json..."
sudo mkdir -p "$(dirname "$RECORDS_PATH")"
if [[ -f "$DOTFILES_ROOT/headscale/extra-records-xcvr.json" ]]; then
  sudo cp "$DOTFILES_ROOT/headscale/extra-records-xcvr.json" "$RECORDS_PATH"
else
  sudo tee "$RECORDS_PATH" > /dev/null << 'EOF'
[
  {"name": "sso.xcvr.link", "type": "A", "value": "192.168.0.158"},
  {"name": "nas.xcvr.link", "type": "A", "value": "192.168.0.158"},
  {"name": "rules.xcvr.link", "type": "A", "value": "192.168.0.158"},
  {"name": "immich.xcvr.link", "type": "A", "value": "192.168.0.158"},
  {"name": "n8n.xcvr.link", "type": "A", "value": "192.168.0.158"},
  {"name": "syncthing.xcvr.link", "type": "A", "value": "192.168.0.158"},
  {"name": "pi5.xcvr.link", "type": "A", "value": "192.168.0.136"},
  {"name": "jellyfin.xcvr.link", "type": "A", "value": "192.168.0.158"},
  {"name": "music.xcvr.link", "type": "A", "value": "192.168.0.158"},
  {"name": "jet.xcvr.link", "type": "A", "value": "192.168.0.197"}
]
EOF
fi
sudo chown 568:568 "$RECORDS_PATH"
echo "   Created: $RECORDS_PATH"
echo ""

# Try to find Headscale config
echo "2. Looking for Headscale config..."
CONFIG_CANDIDATES=(
  "/mnt/.ix-apps/app_configs/headscale"
  "/mnt/tank/apps/headscale"
)
CONFIG_FOUND=""
for base in "${CONFIG_CANDIDATES[@]}"; do
  if [[ -d "$base" ]]; then
    cfg=$(find "$base" -name "config.yaml" -o -name "*.yaml" 2>/dev/null | head -1)
    if [[ -n "$cfg" ]]; then
      CONFIG_FOUND="$cfg"
      break
    fi
  fi
done

if [[ -n "$CONFIG_FOUND" ]]; then
  echo "   Found: $CONFIG_FOUND"
  if grep -q "extra_records" "$CONFIG_FOUND" 2>/dev/null; then
    echo "   Config already has extra_records section."
  else
    echo ""
    echo "   Add this to the dns section of $CONFIG_FOUND:"
    echo "   ---"
    echo "   dns:"
    echo "     extra_records_path: $RECORDS_PATH"
    echo "   ---"
    echo "   Then: Apps → headscale → Edit → Save (to redeploy)"
  fi
else
  echo "   Config not found in standard locations."
fi
echo ""

# Try midclt update (app may support extra_records_path)
echo "3. Attempting app config update via midclt..."
if midclt call -j app.update headscale "{\"values\": {\"headscale\": {\"dns\": {\"extra_records_path\": \"$RECORDS_PATH\"}}}}" 2>/dev/null; then
  echo "   Update submitted. App may redeploy."
else
  echo "   midclt update not supported or failed."
  echo "   Configure manually via Apps → headscale → Edit."
fi
echo ""

echo "=== Manual steps (if needed) ==="
echo "1. Apps → Installed → headscale → Edit"
echo "2. Find DNS / MagicDNS / Extra Records section"
echo "3. Set extra_records_path to: $RECORDS_PATH"
echo "   Or add extra_records with the 8 xcvr.link entries"
echo "4. Save (app will redeploy)"
echo ""
echo "Verify from Mac (with Tailscale connected):"
echo "  dig +short immich.xcvr.link @100.100.100.100"
echo "  # Should return: 192.168.0.158"
echo ""
echo "See: docs/networking/headscale-xcvr-dns-seamless.md"

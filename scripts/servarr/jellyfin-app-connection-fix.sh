#!/bin/bash
# Fix Jellyfin app connection to jellyfin.xcvr.link
# Run from Mac: ./scripts/servarr/jellyfin-app-connection-fix.sh
#
# Issues addressed:
# - DNS resolution (UniFi + Headscale)
# - NPM proxy host configuration
# - WebSocket support for app features

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== Jellyfin App Connection Fix ==="
echo ""

# 1. Ensure DNS records exist
echo "1. Checking DNS..."
DNS_RESULT=$(dig +short jellyfin.xcvr.link @192.168.0.1 2>/dev/null || echo "")
if [ -z "$DNS_RESULT" ]; then
  echo "   Adding DNS record to UniFi..."
  bash "$DOTFILES_ROOT/unifi/add-local-dns-via-ssh.sh" 2>&1 | grep -E "(jellyfin|Done)" || true
else
  echo "   DNS OK: jellyfin.xcvr.link → $DNS_RESULT"
fi

# 2. Ensure NPM proxy host exists
echo ""
echo "2. Checking NPM proxy host..."
if [ -f "$DOTFILES_ROOT/scripts/npm/.env" ]; then
  cd "$DOTFILES_ROOT"
  source scripts/npm/.env 2>/dev/null || true
  
  # Check if jellyfin proxy exists
  if bash scripts/npm/npm-api.sh list 2>/dev/null | grep -q "jellyfin.xcvr.link"; then
    echo "   NPM proxy host exists"
    echo "   Ensuring WebSocket support..."
    bash scripts/npm/npm-api.sh fix-jellyfin 2>&1 | grep -E "(jellyfin|error|Error)" || echo "   WebSocket configured"
  else
    echo "   Adding jellyfin proxy host..."
    bash scripts/npm/npm-api.sh add-jellyfin 2>&1 | grep -E "(jellyfin|error|Error)" || echo "   Added"
  fi
else
  echo "   Warning: scripts/npm/.env not found. Skipping NPM check."
  echo "   To add manually: NPM Admin → Proxy Hosts → Add → Domain: jellyfin.xcvr.link → Forward: 192.168.0.136:8096"
fi

# 3. Test connection
echo ""
echo "3. Testing connection..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 5 -H "Host: jellyfin.xcvr.link" "http://192.168.0.158/" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "200" ]; then
  echo "   ✅ Proxy working (HTTP $HTTP_CODE)"
else
  echo "   ⚠️  Proxy test failed (HTTP $HTTP_CODE)"
fi

# 4. DNS resolution check
echo ""
echo "4. DNS resolution check..."
MAC_DNS=$(scutil --dns 2>/dev/null | grep "nameserver\[0\]" | head -1 | awk '{print $3}' || echo "unknown")
echo "   Mac DNS: $MAC_DNS"
if [[ "$MAC_DNS" == "100.100.100.100" ]]; then
  echo "   ⚠️  Using Tailscale DNS - ensure Headscale has jellyfin.xcvr.link"
  echo "   Run: ./scripts/truenas/headscale-add-xcvr-dns.sh"
elif [[ "$MAC_DNS" == "192.168.0.1" ]]; then
  echo "   ✅ Using UDM Pro DNS"
fi

echo ""
echo "=== Connection URLs for Jellyfin App ==="
echo ""
echo "Try these URLs in the Jellyfin app:"
echo ""
echo "1. http://jellyfin.xcvr.link"
echo "   (Requires DNS resolution - use UDM Pro DNS or Headscale)"
echo ""
echo "2. http://192.168.0.136:8096"
echo "   (Direct IP - works if on same network)"
echo ""
echo "3. http://pi5.xcvr.link:8096"
echo "   (If pi5.xcvr.link resolves)"
echo ""
echo "If app still can't connect:"
echo "  - Check Mac DNS: System Settings → Network → DNS"
echo "  - Ensure UDM Pro (192.168.0.1) is first DNS server"
echo "  - Or add Headscale DNS records: ./scripts/truenas/headscale-add-xcvr-dns.sh"
echo ""

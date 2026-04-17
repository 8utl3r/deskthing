#!/usr/bin/env bash
# Configure macOS to use UDM Pro (192.168.0.1) for xcvr.link DNS
# This makes xcvr.link resolve correctly whether on LAN or Tailscale.
# Run with: sudo ./scripts/macos-configure-xcvr-resolver.sh

set -e

RESOLVER_DIR="/etc/resolver"
RESOLVER_FILE="$RESOLVER_DIR/xcvr.link"
NAMESERVER="192.168.0.1"

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo $0"
  exit 1
fi

mkdir -p "$RESOLVER_DIR"
echo "nameserver $NAMESERVER" > "$RESOLVER_FILE"
echo "Created $RESOLVER_FILE"
echo ""
echo "Verify: dig +short immich.xcvr.link"
echo "(Should return 192.168.0.158)"

#!/usr/bin/env bash
# Headscale: Create pre-auth key for UDM Pro and approve routes
# Run on TrueNAS Shell (System Settings → Advanced → Shell)
# Requires: sudo docker access
#
# Usage:
#   1. Run this script first to create the key
#   2. Copy the preauthkey output
#   3. Use it when configuring UDM Pro (see unifi/udm-pro-headscale-setup.sh)
#   4. After UDM Pro connects, run this script again with --approve to approve routes

set -e

HEADSCALE_CONTAINER="${HEADSCALE_CONTAINER:-ix-headscale-headscale-1}"
USER_NAME="pete"
ROUTES="192.168.0.0/24"

approve_routes() {
  echo "=== Listing nodes and routes ==="
  sudo docker exec "$HEADSCALE_CONTAINER" headscale nodes list
  sudo docker exec "$HEADSCALE_CONTAINER" headscale nodes list-routes
  echo ""
  NODE_ID="${2:-}"
  if [ -z "$NODE_ID" ]; then
    NODE_ID=$(sudo docker exec "$HEADSCALE_CONTAINER" headscale nodes list-routes -o json 2>/dev/null | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
  fi
  if [ -n "$NODE_ID" ]; then
    echo "Approving routes for node $NODE_ID..."
    sudo docker exec "$HEADSCALE_CONTAINER" headscale nodes approve-routes --identifier "$NODE_ID" --routes "$ROUTES"
    echo "Routes approved."
    sudo docker exec "$HEADSCALE_CONTAINER" headscale nodes list-routes
  else
    echo "To approve routes, run (replace NODE_ID with the UDM Pro ID from above):"
    echo "  $0 --approve NODE_ID"
  fi
}

create_key() {
  echo "=== Creating pre-auth key for UDM Pro ==="
  echo "User: $USER_NAME"
  echo "Expiration: 168h (7 days)"
  echo ""
  KEY=$(sudo docker exec "$HEADSCALE_CONTAINER" headscale preauthkeys create -u 1 --reusable --expiration 168h 2>/dev/null | grep -oE 'preauthkey:[a-zA-Z0-9_-]+' | head -1)
  if [ -z "$KEY" ]; then
    echo "Failed to create key. Try running manually (user ID 1 = pete):"
    echo "  sudo docker exec $HEADSCALE_CONTAINER headscale preauthkeys create -u 1 --reusable --expiration 168h"
    exit 1
  fi
  echo "Pre-auth key created:"
  echo ""
  echo "  $KEY"
  echo ""
  echo "Copy the line above and use it in the UDM Pro .env as:"
  echo "  TAILSCALE_FLAGS=\"--login-server=http://192.168.0.158:30210 --advertise-routes=$ROUTES --accept-routes --auth-key=$KEY --reset\""
  echo ""
  echo "After the UDM Pro connects to Headscale, run this script with --approve to approve routes."
}

case "${1:-}" in
  --approve)
    approve_routes "$@"
    ;;
  *)
    create_key
    ;;
esac

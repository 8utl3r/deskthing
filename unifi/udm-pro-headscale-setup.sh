#!/usr/bin/env bash
# UDM Pro Headscale subnet router setup
# Run in Debug Console (Devices → Router → Settings → Manage → Debug)
#
# Prerequisites:
#   1. Run scripts/truenas/headscale-udm-pro-setup.sh on TrueNAS to get pre-auth key
#   2. tailscaled already stopped and disabled (systemctl stop tailscaled; systemctl disable tailscaled)
#
# Usage: Paste PREAUTHKEY and run, or: PREAUTHKEY=preauthkey:xxx bash -c "$(curl -sSL https://raw.githubusercontent.com/...)" 
# For local: PREAUTHKEY=preauthkey:YOUR_KEY bash udm-pro-headscale-setup.sh

set -e

HEADSCALE_URL="http://192.168.0.158:30210"
ROUTES="192.168.0.0/24"
UNIFIOS_TAILSCALE="/data/unifios-tailscale"

PREAUTHKEY="${PREAUTHKEY:-$1}"
if [ -z "$PREAUTHKEY" ]; then
  echo "Usage: $0 preauthkey:YOUR_KEY"
  echo "   or: PREAUTHKEY=preauthkey:YOUR_KEY $0"
  echo "Get the key by running scripts/truenas/headscale-udm-pro-setup.sh on TrueNAS"
  exit 1
fi

echo "=== Installing unifios-tailscale ==="
curl -sSLq https://raw.githubusercontent.com/gridironsolutions/unifios-tailscale/master/remote-install.sh | sh

echo ""
echo "=== Configuring for Headscale ==="
mkdir -p "$UNIFIOS_TAILSCALE"
cat > "$UNIFIOS_TAILSCALE/.env" << EOF
TAILSCALE_FLAGS="--login-server=$HEADSCALE_URL --advertise-routes=$ROUTES --accept-routes --auth-key=$PREAUTHKEY --reset"
AUTOMATICALLY_UPGRADE_TAILSCALE="false"
EOF

echo "=== Enabling IP forwarding ==="
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

echo "=== Restarting unifios-tailscale ==="
"$UNIFIOS_TAILSCALE/unifios-tailscale.sh" restart

echo ""
echo "=== Status ==="
"$UNIFIOS_TAILSCALE/unifios-tailscale.sh" status
tailscale status

echo ""
echo "Next: On TrueNAS, run headscale-udm-pro-setup.sh --approve to approve routes"

#!/usr/bin/env bash
# Run this in UDM Pro Debug Console. Pre-auth key is pre-filled.
# Copy and paste the entire block into the Debug Console.

PREAUTHKEY="preauthkey:fbb092a4676bbabf2434442a0b12ff307053036b9dbc6ba3"
set -e
HEADSCALE_URL="http://192.168.0.158:30210"
ROUTES="192.168.0.0/24"
UNIFIOS_TAILSCALE="/data/unifios-tailscale"

curl -sSLq https://raw.githubusercontent.com/gridironsolutions/unifios-tailscale/master/remote-install.sh | sh

mkdir -p "$UNIFIOS_TAILSCALE"
echo "TAILSCALE_FLAGS=\"--login-server=$HEADSCALE_URL --advertise-routes=$ROUTES --accept-routes --auth-key=$PREAUTHKEY --reset\"" > "$UNIFIOS_TAILSCALE/.env"
echo "AUTOMATICALLY_UPGRADE_TAILSCALE=\"false\"" >> "$UNIFIOS_TAILSCALE/.env"

sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

"$UNIFIOS_TAILSCALE/unifios-tailscale.sh" restart
tailscale status

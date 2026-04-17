#!/usr/bin/env bash
# Set up routing and NAT on a Headscale exit node so exit traffic goes via Mullvad (wg0).
# Run on the exit node host after Tailscale and Mullvad WireGuard are up.
#
# Usage:
#   sudo LAN_GW=192.168.0.1 LAN_DEV=eth0 LAN_CIDR=192.168.0.0/24 HEADSCALE_IP=192.168.0.158 MULLVAD_IF=wg0 ./headscale-exit-node-mullvad-routes.sh
#
# Vars (set via env or edit below):
#   LAN_GW       - Gateway for LAN (and Headscale)
#   LAN_DEV      - LAN interface (e.g. eth0, enp0s3)
#   LAN_CIDR     - LAN subnet (e.g. 192.168.0.0/24)
#   HEADSCALE_IP - Headscale server IP (so it's reached via LAN, not Mullvad)
#   MULLVAD_IF   - Mullvad WireGuard interface (default wg0)

set -e

LAN_GW="${LAN_GW:-192.168.0.1}"
LAN_DEV="${LAN_DEV:-eth0}"
LAN_CIDR="${LAN_CIDR:-192.168.0.0/24}"
HEADSCALE_IP="${HEADSCALE_IP:-192.168.0.158}"
MULLVAD_IF="${MULLVAD_IF:-wg0}"

if [[ $(id -u) -ne 0 ]]; then
  echo "Run as root (e.g. sudo)" >&2
  exit 1
fi

# Ensure LAN and Headscale don't go over Mullvad (more specific routes)
ip route add "$LAN_CIDR" via "$LAN_GW" dev "$LAN_DEV" 2>/dev/null || true
ip route add "$HEADSCALE_IP/32" via "$LAN_GW" dev "$LAN_DEV" 2>/dev/null || true

# NAT: traffic from tailscale0 exiting via Mullvad
if command -v iptables >/dev/null 2>&1; then
  iptables -t nat -C POSTROUTING -o "$MULLVAD_IF" -j MASQUERADE 2>/dev/null || \
  iptables -t nat -A POSTROUTING -o "$MULLVAD_IF" -j MASQUERADE
fi

echo "Routes and NAT set: LAN $LAN_CIDR and $HEADSCALE_IP via $LAN_DEV; NAT out $MULLVAD_IF."
echo "Make these persistent with your distro (e.g. netplan, if-up.d, or systemd)."

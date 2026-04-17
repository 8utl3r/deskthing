#!/usr/bin/env bash
# Domotz PRO Agent install on Raspberry Pi 5 (native, not Docker)
# Reference: https://help.domotz.com/onboarding-guides/domotz-installation-raspberry-pi/
#
# Run on Pi5: sudo bash servarr-pi5-domotz-install.sh
# After install: open http://<pi-ip>:3000 or use Domotz mobile app to add site

set -e

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo" >&2
  exit 1
fi

echo "=== Domotz PRO Agent install on Pi5 (native) ==="

# 1. Install snapd
echo "Installing snapd..."
apt-get update
apt-get install -y snapd

# 2. Install Domotz snap and connect interfaces
echo "Installing Domotz PRO Agent..."
snap install domotzpro-agent-publicstore
snap connect domotzpro-agent-publicstore:firewall-control
snap connect domotzpro-agent-publicstore:network-observe
snap connect domotzpro-agent-publicstore:raw-usb
snap connect domotzpro-agent-publicstore:shutdown
snap connect domotzpro-agent-publicstore:system-observe

# 3. Load tun module for VPN on Demand
echo "Loading tun module..."
if ! grep -q '^tun$' /etc/modules 2>/dev/null; then
  echo tun >> /etc/modules
fi
modprobe tun

# 4. Disable libarmmem preload if present (conflicts with snap/VPN)
if [[ -f /etc/ld.so.preload ]]; then
  if grep -q 'libarmmem' /etc/ld.so.preload; then
    echo "Commenting libarmmem in /etc/ld.so.preload..."
    sed -i 's|^/usr/lib/.*libarmmem|#&|' /etc/ld.so.preload
  fi
fi

# 5. Restart Domotz
echo "Restarting Domotz agent..."
snap restart domotzpro-agent-publicstore

# 6. Comment Include in /etc/ssh/ssh_config if present (avoids remote-session conflicts)
if [[ -f /etc/ssh/ssh_config ]] && grep -q '^Include /etc/ssh/ssh_config.d/\*\.conf' /etc/ssh/ssh_config; then
  echo "Commenting Include in /etc/ssh/ssh_config..."
  sed -i 's|^Include /etc/ssh/ssh_config.d/\*\.conf|#&|' /etc/ssh/ssh_config
fi

echo ""
echo "=== Domotz installed successfully ==="
echo ""
echo "Next steps:"
echo "  1. Set time correctly if needed: sudo timedatectl set-ntp true"
echo "  2. Open http://$(hostname -I | awk '{print $1}'):3000 in a browser"
echo "     (or use Domotz mobile app → Add Site when on same LAN)"
echo "  3. Create/login to Domotz account, name the collector, activate"
echo ""
echo "Note: If port 3000 is in use, Domotz will use 3001 automatically."

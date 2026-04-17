#!/bin/bash
# Add your Mac's SSH key to the Pi 5 via KVM console (no password needed)
# Run on Mac, then paste the output into the Pi's console (KVM)
#
# Flow:
#   1. Run this script on your Mac
#   2. Switch KVM to Pi 5, get to a shell (login as pi)
#   3. Copy and paste the entire "PASTE THIS" block into the Pi console
#   4. Press Enter
#   5. SSH from Mac will work: ssh pi@192.168.0.136

set -e
KEY_FILE="${1:-$HOME/.ssh/id_ed25519.pub}"
if [ ! -f "$KEY_FILE" ]; then
  KEY_FILE="$HOME/.ssh/id_rsa.pub"
fi
if [ ! -f "$KEY_FILE" ]; then
  echo "No SSH public key found. Run: ssh-keygen -t ed25519 -N ''"
  exit 1
fi

KEY=$(cat "$KEY_FILE")
KEY_B64=$(echo -n "$KEY" | base64)

echo ""
echo "=== SSH key setup via KVM ==="
echo ""
echo "1. Switch KVM to Pi 5 (Jet KVM: http://192.168.0.197)"
echo "2. Log in as pi if needed"
echo "3. Copy the ENTIRE line below and paste it into the Pi console, then press Enter:"
echo ""
echo "--- PASTE THIS ON THE PI ---"
printf "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '%s' | base64 -d >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && echo Done\n" "$KEY_B64"
echo "--- END ---"
echo ""
echo "4. Test from Mac: ssh pi@192.168.0.136"
echo ""

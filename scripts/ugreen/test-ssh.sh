#!/usr/bin/env bash
# Test SSH connection to Ugreen DXP2800

echo "Testing SSH connection to Pete@192.168.0.158..."
echo ""
echo "If this hangs or fails, try running manually:"
echo "  ssh Pete@192.168.0.158"
echo ""

# Try with password authentication only
ssh -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no \
    -o StrictHostKeyChecking=no \
    Pete@192.168.0.158 \
    "uname -a && echo '---' && lsblk -o NAME,SIZE,TYPE && echo '---' && ip addr show | head -20"

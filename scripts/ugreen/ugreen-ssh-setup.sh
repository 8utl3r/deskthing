#!/usr/bin/env bash
# Ugreen DXP2800 SSH Setup and System Information Gathering
# Run this script interactively - it will prompt for password

set -euo pipefail

NAS_IP="192.168.0.158"
NAS_USER="Pete"
SSH_KEY="$HOME/.ssh/id_ed25519.pub"

echo "=== Ugreen DXP2800 SSH Setup ==="
echo ""

# Step 1: Copy SSH key
echo "Step 1: Setting up SSH key authentication..."
echo "You'll be prompted for your password: $NAS_USER@$NAS_IP"
echo ""

if ssh-copy-id -i "$SSH_KEY" "$NAS_USER@$NAS_IP" 2>&1; then
    echo "✅ SSH key copied successfully!"
else
    echo "⚠️  SSH key copy failed. You may need to manually add the key."
    echo "Public key to add:"
    cat "$SSH_KEY"
    echo ""
    echo "Run this on the NAS:"
    echo "  mkdir -p ~/.ssh"
    echo "  echo '$(cat $SSH_KEY)' >> ~/.ssh/authorized_keys"
    echo "  chmod 700 ~/.ssh"
    echo "  chmod 600 ~/.ssh/authorized_keys"
fi

echo ""
echo "Step 2: Gathering system information..."
echo ""

# Step 2: Gather system info
ssh "$NAS_USER@$NAS_IP" << 'EOF'
echo "=== System Information ==="
uname -a
echo ""
echo "=== OS Release ==="
cat /etc/os-release 2>/dev/null || echo "No os-release file"
echo ""
echo "=== Disk Layout ==="
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
echo ""
echo "=== Network Interfaces ==="
ip addr show
echo ""
echo "=== PCI Devices (NVMe, Network) ==="
lspci | grep -iE 'nvme|network|ethernet' || echo "lspci not available"
echo ""
echo "=== Filesystem Usage ==="
df -h
echo ""
echo "=== eMMC Devices ==="
ls -la /dev/mmcblk* 2>/dev/null || echo "No mmcblk devices found"
echo ""
echo "=== NVMe Devices ==="
ls -la /dev/nvme* 2>/dev/null || echo "No nvme devices found"
echo ""
echo "=== System Info ==="
hostname
uptime
echo ""
echo "=== Sudo Check ==="
sudo -n whoami 2>/dev/null && echo "Passwordless sudo: YES" || echo "Passwordless sudo: NO (will need password)"
EOF

echo ""
echo "✅ System information gathered!"
echo ""
echo "Next steps:"
echo "1. Review the system information above"
echo "2. We'll backup UGOS firmware"
echo "3. Prepare for TrueNAS installation"

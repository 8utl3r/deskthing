#!/usr/bin/env bash
# Quick script to gather Ugreen DXP2800 system info
# Run this interactively - it will prompt for password once

set -euo pipefail

NAS_IP="192.168.0.158"
NAS_USER="Pete"

echo "Connecting to $NAS_USER@$NAS_IP..."
echo "You'll be prompted for password: n0ypSGlWEflFZr"
echo ""

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

echo "=== PCI Devices ==="
lspci 2>/dev/null | grep -iE 'nvme|network|ethernet|intel' || echo "lspci not available or no matches"
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

echo "=== SATA Devices ==="
ls -la /dev/sd* 2>/dev/null || echo "No sda devices found"
echo ""

echo "=== System Info ==="
hostname
uptime
echo ""

echo "=== Check Sudo Access ==="
sudo -n whoami 2>/dev/null && echo "Passwordless sudo: YES" || echo "Passwordless sudo: NO"
EOF

echo ""
echo "✅ Information gathered!"

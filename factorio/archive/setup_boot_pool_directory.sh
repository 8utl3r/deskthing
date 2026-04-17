#!/bin/bash
# Setup script for Factorio directory on boot-pool
# Run this on TrueNAS after boot-pool is working

# Create directory structure
sudo mkdir -p /mnt/boot-pool/apps/factorio

# Set permissions (apps user/group = 568:568)
sudo chown -R apps:apps /mnt/boot-pool/apps/factorio
sudo chmod 755 /mnt/boot-pool/apps/factorio

# Verify
ls -la /mnt/boot-pool/apps/
echo ""
echo "✅ Directory created: /mnt/boot-pool/apps/factorio"
echo "✅ Permissions set: apps:apps (568:568)"
echo ""
echo "Ready to deploy Factorio!"

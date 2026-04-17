#!/bin/bash
# Script to check the RCON password from the running Factorio container

echo "Checking RCON password from running Factorio container..."
echo ""

# SSH to TrueNAS and check the container
echo "Run this on TrueNAS (SSH):"
echo ""
echo "docker exec factorio cat /opt/factorio/config/rconpw 2>/dev/null || echo 'Password file not found'"
echo ""
echo "Or check docker-compose.yml:"
echo "cd /mnt/boot-pool/apps/factorio && grep FACTORIO_RCON_PASSWORD docker-compose.yml"
echo ""
echo "Or check container environment:"
echo "docker inspect factorio | grep -A 5 FACTORIO_RCON_PASSWORD"

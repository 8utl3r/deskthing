#!/bin/bash
# Script to retrieve RCON password from TrueNAS Factorio container

echo "Retrieving RCON password from TrueNAS..."
echo ""

# Instructions for manual retrieval
echo "Run these commands on TrueNAS (via SSH):"
echo ""
echo "1. Check the password file in the container:"
echo "   docker exec factorio cat /opt/factorio/config/rconpw"
echo ""
echo "2. Or check docker-compose.yml:"
echo "   cd /mnt/boot-pool/apps/factorio && grep FACTORIO_RCON_PASSWORD docker-compose.yml"
echo ""
echo "3. Or check container environment variables:"
echo "   docker inspect factorio | grep -A 2 FACTORIO_RCON_PASSWORD"
echo ""
echo "4. Or check server logs for the password (it's printed on startup):"
echo "   docker logs factorio | grep -i 'rcon password'"
echo ""

# If user wants to automate via SSH (requires SSH key setup)
if [ "$1" == "--auto" ]; then
    echo "Attempting automatic retrieval via SSH..."
    echo ""
    
    # Try to get password via SSH
    PASSWORD=$(ssh truenas_admin@192.168.0.158 "docker exec factorio cat /opt/factorio/config/rconpw 2>/dev/null" 2>/dev/null)
    
    if [ -n "$PASSWORD" ]; then
        echo "✅ Found password: $PASSWORD"
        echo ""
        echo "Update config.py with:"
        echo "RCON_PASSWORD = \"$PASSWORD\""
    else
        echo "❌ Could not retrieve password automatically."
        echo "   Please run the commands above manually."
    fi
fi

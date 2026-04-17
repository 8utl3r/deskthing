#!/bin/bash
# Quick script to check Factorio server status and logs
# Run on TrueNAS via SSH

echo "🔍 Factorio Server Status Check"
echo "================================"
echo ""

# Check if container is running
echo "1️⃣  Container Status:"
if sudo docker ps | grep -q factorio; then
    echo "✅ Container is RUNNING"
    sudo docker ps | grep factorio
else
    echo "❌ Container is NOT running"
    echo ""
    echo "Checking stopped containers..."
    sudo docker ps -a | grep factorio
    exit 1
fi

echo ""
echo "2️⃣  Network Mode:"
NETWORK_MODE=$(sudo docker inspect factorio | grep -A 5 '"NetworkMode"' | grep -v "null" | head -1 | cut -d'"' -f4)
echo "   Network Mode: $NETWORK_MODE"
if [ "$NETWORK_MODE" = "host" ]; then
    echo "   ✅ Using host network (UDP will work)"
else
    echo "   ⚠️  Not using host network"
fi

echo ""
echo "3️⃣  Port Status:"
if sudo netstat -ulnp 2>/dev/null | grep -q 34197; then
    echo "   ✅ UDP port 34197 is LISTENING"
    sudo netstat -ulnp 2>/dev/null | grep 34197
else
    echo "   ❌ UDP port 34197 is NOT listening"
fi

if sudo netstat -tlnp 2>/dev/null | grep -q 27015; then
    echo "   ✅ TCP port 27015 is LISTENING"
    sudo netstat -tlnp 2>/dev/null | grep 27015
else
    echo "   ❌ TCP port 27015 is NOT listening"
fi

echo ""
echo "4️⃣  Recent Logs (last 20 lines):"
echo "   (Press Ctrl+C to exit log view)"
echo ""
sudo docker logs --tail 20 factorio

echo ""
echo "📋 Useful Commands:"
echo "   View all logs:        sudo docker logs factorio"
echo "   Follow logs (live):   sudo docker logs -f factorio"
echo "   Check status:         sudo docker ps | grep factorio"
echo "   Restart:              cd /mnt/boot-pool/apps/factorio && sudo docker compose restart"
echo "   Stop:                 cd /mnt/boot-pool/apps/factorio && sudo docker compose down"
echo "   Start:                cd /mnt/boot-pool/apps/factorio && sudo docker compose up -d"

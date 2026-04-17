#!/bin/bash
# Shell script to fix Factorio UDP networking via host network mode
# Run this on TrueNAS via SSH

set -e

echo "🔧 Factorio Host Network Fix"
echo "============================"
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  This script needs root/sudo access"
    echo "Run with: sudo $0"
    exit 1
fi

echo "1️⃣  Checking current Factorio container status..."
echo ""

# Check if container exists
if docker ps -a | grep -q factorio; then
    echo "✅ Factorio container found"
    docker ps -a | grep factorio
else
    echo "❌ Factorio container not found"
    echo "   Is the app deployed in TrueNAS?"
    exit 1
fi

echo ""
echo "2️⃣  Checking if container is running..."
if docker ps | grep -q factorio; then
    echo "✅ Container is running"
    CONTAINER_ID=$(docker ps | grep factorio | awk '{print $1}')
else
    echo "⚠️  Container is not running"
    echo "   Starting container..."
    docker start factorio
    sleep 2
    CONTAINER_ID=$(docker ps | grep factorio | awk '{print $1}')
    if [ -z "$CONTAINER_ID" ]; then
        echo "❌ Failed to start container"
        exit 1
    fi
fi

echo ""
echo "3️⃣  Checking current network mode..."
NETWORK_MODE=$(docker inspect $CONTAINER_ID | grep -A 5 '"NetworkMode"' | grep -v "null" | head -1 | cut -d'"' -f4)
echo "   Current network mode: $NETWORK_MODE"

if [ "$NETWORK_MODE" = "host" ]; then
    echo "✅ Already using host network!"
    exit 0
fi

echo ""
echo "4️⃣  Stopping TrueNAS app (if managed by TrueNAS)..."
# Try to stop via TrueNAS if it's a Custom App
if command -v midclt >/dev/null 2>&1; then
    echo "   Stopping via TrueNAS API..."
    midclt call chart.release.scale '{"release_name": "factorio", "scale_options": {"replica_count": 0}}' 2>/dev/null || echo "   (Not managed by TrueNAS or already stopped)"
fi

echo ""
echo "5️⃣  Stopping container..."
docker stop factorio 2>/dev/null || true
sleep 2

echo ""
echo "6️⃣  Removing old container..."
docker rm factorio 2>/dev/null || true

echo ""
echo "7️⃣  Starting with host network mode..."
echo ""

# Get the original container config
IMAGE=$(docker inspect $CONTAINER_ID 2>/dev/null | grep -A 1 '"Image"' | grep -v "null" | head -1 | cut -d'"' -f4 || echo "goofball222/factorio:latest")
ENV_VARS=$(docker inspect $CONTAINER_ID 2>/dev/null | grep -A 20 '"Env"' | grep -v "null" | grep '"' | sed 's/.*"\(.*\)".*/\1/' | tr '\n' ' ' || echo "")

# Extract RCON password from env
RCON_PASSWORD=$(echo "$ENV_VARS" | grep -o 'FACTORIO_RCON_PASSWORD=[^ ]*' | cut -d'=' -f2 || echo "")

if [ -z "$RCON_PASSWORD" ]; then
    echo "⚠️  Could not find RCON password in container config"
    echo "   You'll need to set it manually"
    RCON_PASSWORD="CHANGE_THIS_PASSWORD"
fi

# Get volume mount
VOLUME_MOUNT=$(docker inspect $CONTAINER_ID 2>/dev/null | grep -A 5 '"Mounts"' | grep '"Source"' | head -1 | cut -d'"' -f4 || echo "/mnt/boot-pool/apps/factorio")

echo "   Image: $IMAGE"
echo "   Volume: $VOLUME_MOUNT"
echo "   RCON Password: [hidden]"
echo ""

# Start with host network
docker run -d \
    --name factorio \
    --restart unless-stopped \
    --network host \
    -e FACTORIO_RCON_PASSWORD="$RCON_PASSWORD" \
    -e FACTORIO_SAVE=my-save \
    -v "$VOLUME_MOUNT:/factorio" \
    --memory=2g \
    --memory-reservation=512m \
    --cpus=2 \
    "$IMAGE"

echo ""
echo "8️⃣  Verifying new container..."
sleep 2

if docker ps | grep -q factorio; then
    echo "✅ Container started successfully with host network!"
    echo ""
    echo "9️⃣  Checking network mode..."
    NEW_NETWORK=$(docker inspect factorio | grep -A 5 '"NetworkMode"' | grep -v "null" | head -1 | cut -d'"' -f4)
    if [ "$NEW_NETWORK" = "host" ]; then
        echo "✅ Confirmed: Using host network mode"
    else
        echo "⚠️  Network mode: $NEW_NETWORK (may still work)"
    fi
    
    echo ""
    echo "🔟 Checking if ports are accessible..."
    if netstat -ulnp 2>/dev/null | grep -q 34197; then
        echo "✅ UDP port 34197 is listening"
    else
        echo "⚠️  UDP port 34197 not found (may take a moment to start)"
    fi
    
    if netstat -tlnp 2>/dev/null | grep -q 27015; then
        echo "✅ TCP port 27015 is listening"
    else
        echo "⚠️  TCP port 27015 not found (may take a moment to start)"
    fi
    
    echo ""
    echo "✅ Done! Container is running with host network."
    echo ""
    echo "📋 Next steps:"
    echo "   1. Check if server appears in Factorio LAN browser"
    echo "   2. Try connecting: 192.168.0.158:34197"
    echo "   3. Test RCON: 192.168.0.158:27015"
    echo ""
    echo "⚠️  Note: This container is now managed outside TrueNAS UI"
    echo "   To manage it, use: docker start/stop/restart factorio"
    
else
    echo "❌ Failed to start container"
    echo "   Check logs: docker logs factorio"
    exit 1
fi

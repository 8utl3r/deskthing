#!/bin/bash
# Quick script to fix UDP by switching to Docker Compose with host network
# Run this on TrueNAS via SSH

set -e

FACTORIO_DIR="/mnt/boot-pool/apps/factorio"
COMPOSE_FILE="$FACTORIO_DIR/docker-compose.yml"

echo "🔧 Fixing Factorio UDP Networking"
echo "================================="
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  This script needs root/sudo access"
    echo "Run with: sudo $0"
    exit 1
fi

# Stop TrueNAS-managed container
echo "1️⃣  Stopping TrueNAS-managed container..."
docker stop factorio 2>/dev/null || echo "   (Container not running or not found)"
docker rm factorio 2>/dev/null || echo "   (Container not found)"

# Create directory if needed
if [ ! -d "$FACTORIO_DIR" ]; then
    echo "📁 Creating directory: $FACTORIO_DIR"
    mkdir -p "$FACTORIO_DIR"
    chown -R apps:apps "$FACTORIO_DIR"
fi

# Create docker-compose.yml
echo ""
echo "2️⃣  Creating docker-compose.yml with host network..."
cat > "$COMPOSE_FILE" << 'EOF'
version: '3.8'

services:
  factorio:
    image: factoriotools/factorio:latest
    container_name: factorio
    restart: unless-stopped
    network_mode: host
    environment:
      - FACTORIO_RCON_PASSWORD=4hyZA96uO9PuWl
      - FACTORIO_SAVE=save
    volumes:
      - /mnt/boot-pool/apps/factorio:/factorio
    mem_limit: 2g
    mem_reservation: 512m
    cpus: '2'
EOF

chmod 644 "$COMPOSE_FILE"
echo "✅ Created: $COMPOSE_FILE"

# Check for docker-compose
echo ""
echo "3️⃣  Checking for docker-compose..."
if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
    echo "✅ Using: docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
    echo "✅ Using: docker-compose"
else
    echo "⚠️  docker-compose not found, installing..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y docker-compose
        COMPOSE_CMD="docker-compose"
    else
        echo "❌ Could not install docker-compose"
        echo "   Please install manually, then run:"
        echo "   cd $FACTORIO_DIR && docker-compose up -d"
        exit 1
    fi
fi

# Start with docker-compose
echo ""
echo "4️⃣  Starting Factorio with host network mode..."
cd "$FACTORIO_DIR"
$COMPOSE_CMD up -d

# Wait a moment
sleep 3

# Verify
echo ""
echo "5️⃣  Verifying setup..."
if docker ps | grep -q factorio; then
    echo "✅ Container is running"
    
    # Check network mode
    NETWORK_MODE=$(docker inspect factorio | grep -A 5 '"NetworkMode"' | grep -v "null" | head -1 | cut -d'"' -f4)
    if [ "$NETWORK_MODE" = "host" ]; then
        echo "✅ Using host network mode (UDP will work!)"
    else
        echo "⚠️  Network mode: $NETWORK_MODE (expected: host)"
    fi
    
    # Check ports
    sleep 2  # Give server time to start
    if netstat -ulnp 2>/dev/null | grep -q 34197; then
        echo "✅ UDP port 34197 is listening"
    else
        echo "⚠️  UDP port 34197 not found yet (check logs: docker logs factorio)"
    fi
    
    if netstat -tlnp 2>/dev/null | grep -q 27015; then
        echo "✅ TCP port 27015 is listening"
    else
        echo "⚠️  TCP port 27015 not found yet (check logs: docker logs factorio)"
    fi
    
    echo ""
    echo "✅ Setup complete!"
    echo ""
    echo "📋 Management Commands:"
    echo "   Start:   cd $FACTORIO_DIR && $COMPOSE_CMD up -d"
    echo "   Stop:    cd $FACTORIO_DIR && $COMPOSE_CMD down"
    echo "   Restart: cd $FACTORIO_DIR && $COMPOSE_CMD restart"
    echo "   Logs:    docker logs -f factorio"
    echo "   Status:  docker ps | grep factorio"
    echo ""
    echo "🎮 Test Connection:"
    echo "   1. Check LAN browser in Factorio client"
    echo "   2. Or connect directly: 192.168.0.158:34197"
    echo "   3. RCON: 192.168.0.158:27015"
    echo ""
    echo "⚠️  Note: This container is now managed outside TrueNAS UI"
    echo "   Use the commands above to manage it"
    
else
    echo "❌ Container failed to start"
    echo "   Check logs: docker logs factorio"
    exit 1
fi

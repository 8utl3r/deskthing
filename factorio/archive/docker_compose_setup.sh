#!/bin/bash
# Proper Factorio setup using Docker Compose (bypasses TrueNAS Custom Apps)
# This is the recommended way to run UDP game servers on TrueNAS Scale

set -e

FACTORIO_DIR="/mnt/boot-pool/apps/factorio"
COMPOSE_FILE="$FACTORIO_DIR/docker-compose.yml"

echo "🎮 Factorio Docker Compose Setup"
echo "================================"
echo ""
echo "This sets up Factorio using Docker Compose with host network mode."
echo "This is the recommended way to run UDP game servers on TrueNAS Scale."
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  This script needs root/sudo access"
    echo "Run with: sudo $0"
    exit 1
fi

# Create directory if it doesn't exist
if [ ! -d "$FACTORIO_DIR" ]; then
    echo "📁 Creating directory: $FACTORIO_DIR"
    mkdir -p "$FACTORIO_DIR"
    chown -R apps:apps "$FACTORIO_DIR"
fi

# Check if compose file exists
if [ -f "$COMPOSE_FILE" ]; then
    echo "⚠️  docker-compose.yml already exists at: $COMPOSE_FILE"
    read -p "   Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "   Keeping existing file. Exiting."
        exit 0
    fi
fi

# Get RCON password
echo "🔐 RCON Password Configuration"
echo "   (Leave empty to use default: Ahth7Ahl1ereeC7)"
read -p "   Enter RCON password: " RCON_PASSWORD
if [ -z "$RCON_PASSWORD" ]; then
    RCON_PASSWORD="Ahth7Ahl1ereeC7"
    echo "   Using default password from logs"
fi

# Create docker-compose.yml
echo ""
echo "📝 Creating docker-compose.yml..."
cat > "$COMPOSE_FILE" << EOF
version: '3.8'

services:
  factorio:
    image: goofball222/factorio:latest
    container_name: factorio
    restart: unless-stopped
    network_mode: host
    environment:
      - FACTORIO_RCON_PASSWORD=$RCON_PASSWORD
      - FACTORIO_SAVE=my-save
    volumes:
      - $FACTORIO_DIR:/factorio
    mem_limit: 2g
    mem_reservation: 512m
    cpus: '2'
EOF

chmod 644 "$COMPOSE_FILE"
echo "✅ Created: $COMPOSE_FILE"

# Check if docker-compose is available
if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
    echo ""
    echo "⚠️  docker-compose not found"
    echo "   Installing docker-compose..."
    
    # Try to install docker-compose
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y docker-compose
    elif command -v pip3 >/dev/null 2>&1; then
        pip3 install docker-compose
    else
        echo "   ❌ Could not install docker-compose automatically"
        echo "   Please install it manually, then run:"
        echo "   cd $FACTORIO_DIR && docker-compose up -d"
        exit 1
    fi
fi

# Stop any existing TrueNAS-managed container
echo ""
echo "🛑 Stopping any existing Factorio containers..."
docker stop factorio 2>/dev/null || true
docker rm factorio 2>/dev/null || true

# Start with docker-compose
echo ""
echo "🚀 Starting Factorio with Docker Compose..."
cd "$FACTORIO_DIR"

if docker compose version >/dev/null 2>&1; then
    docker compose up -d
else
    docker-compose up -d
fi

# Wait a moment
sleep 3

# Verify
echo ""
echo "✅ Verification"
echo "==============="

if docker ps | grep -q factorio; then
    echo "✅ Container is running"
    
    # Check network mode
    NETWORK_MODE=$(docker inspect factorio | grep -A 5 '"NetworkMode"' | grep -v "null" | head -1 | cut -d'"' -f4)
    if [ "$NETWORK_MODE" = "host" ]; then
        echo "✅ Using host network mode"
    else
        echo "⚠️  Network mode: $NETWORK_MODE (expected: host)"
    fi
    
    # Check ports
    if netstat -ulnp 2>/dev/null | grep -q 34197; then
        echo "✅ UDP port 34197 is listening"
    else
        echo "⚠️  UDP port 34197 not found (may take a moment)"
    fi
    
    if netstat -tlnp 2>/dev/null | grep -q 27015; then
        echo "✅ TCP port 27015 is listening"
    else
        echo "⚠️  TCP port 27015 not found (may take a moment)"
    fi
    
    echo ""
    echo "✅ Setup complete!"
    echo ""
    echo "📋 Management Commands:"
    echo "   Start:   cd $FACTORIO_DIR && docker compose up -d"
    echo "   Stop:    cd $FACTORIO_DIR && docker compose down"
    echo "   Restart: cd $FACTORIO_DIR && docker compose restart"
    echo "   Logs:    docker logs -f factorio"
    echo "   Status:  docker ps | grep factorio"
    echo ""
    echo "🎮 Test Connection:"
    echo "   In Factorio client: 192.168.0.158:34197"
    echo "   RCON: 192.168.0.158:27015"
    
else
    echo "❌ Container failed to start"
    echo "   Check logs: docker logs factorio"
    exit 1
fi

#!/bin/bash
# Manual commands to fix UDP - run these directly on TrueNAS

# Create docker-compose.yml
mkdir -p /mnt/boot-pool/apps/factorio
cd /mnt/boot-pool/apps/factorio

cat > docker-compose.yml << 'EOF'
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

# Stop any existing container
docker stop factorio 2>/dev/null || true
docker rm factorio 2>/dev/null || true

# Start with docker compose
docker compose up -d

# Wait a moment
sleep 3

# Check status
echo "Checking container status..."
docker ps | grep factorio

echo ""
echo "Checking network mode..."
docker inspect factorio | grep -A 5 '"NetworkMode"'

echo ""
echo "Checking ports..."
netstat -ulnp 2>/dev/null | grep 34197 || echo "UDP port 34197 not found yet (may take a moment)"
netstat -tlnp 2>/dev/null | grep 27015 || echo "TCP port 27015 not found yet (may take a moment)"

echo ""
echo "View logs: docker logs factorio"

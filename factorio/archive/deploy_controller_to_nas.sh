#!/bin/bash
# Deploy Factorio Controller to TrueNAS NAS

NAS_HOST="truenas_admin@192.168.0.158"
NAS_PATH="/mnt/boot-pool/apps/factorio-controller"
LOCAL_PATH="/Users/pete/dotfiles/factorio"

echo "🚀 Deploying Factorio Controller to NAS..."

# Create directory on NAS
ssh $NAS_HOST "sudo mkdir -p $NAS_PATH && sudo chmod 755 $NAS_PATH"

# Copy files
echo "📦 Copying files..."
scp $LOCAL_PATH/factorio_n8n_controller.py \
    $LOCAL_PATH/config.py \
    $LOCAL_PATH/requirements.txt \
    $LOCAL_PATH/Dockerfile.controller \
    $LOCAL_PATH/docker-compose.controller.yml \
    $NAS_HOST:/tmp/

# Move files to final location
echo "📁 Moving files to $NAS_PATH..."
ssh $NAS_HOST "sudo mv /tmp/factorio_n8n_controller.py /tmp/config.py /tmp/requirements.txt /tmp/Dockerfile.controller /tmp/docker-compose.controller.yml $NAS_PATH/ && sudo chmod 644 $NAS_PATH/*"

# Update config.py for NAS environment
echo "⚙️  Updating config for NAS..."
ssh $NAS_HOST "sudo sed -i 's/OLLAMA_HOST = \"localhost\"/OLLAMA_HOST = \"192.168.0.30\"/' $NAS_PATH/config.py"

# Build and start container
echo "🐳 Building and starting container..."
ssh $NAS_HOST "cd $NAS_PATH && sudo docker compose -f docker-compose.controller.yml build && sudo docker compose -f docker-compose.controller.yml up -d"

# Check status
echo "✅ Checking container status..."
ssh $NAS_HOST "sudo docker ps | grep factorio-controller"

echo "🎉 Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Update n8n workflow: Change action executor URL to http://localhost:8080/execute-action"
echo "2. Test: curl -X POST http://192.168.0.158:8080/execute-action -H 'Content-Type: application/json' -d '{\"agent_id\": \"test\", \"action\": \"walk_to\", \"params\": {\"x\": 10, \"y\": 20}}'"

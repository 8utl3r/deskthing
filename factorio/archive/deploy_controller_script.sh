#!/bin/bash
# Deploy Factorio Controller to TrueNAS NAS
# This script copies files and prepares for deployment

set -e

NAS_HOST="truenas_admin@192.168.0.158"
NAS_PATH="/mnt/boot-pool/apps/factorio-controller"
LOCAL_PATH="/Users/pete/dotfiles/factorio"

echo "🚀 Deploying Factorio Controller to NAS..."
echo ""

# Check if files exist
if [ ! -f "$LOCAL_PATH/factorio_n8n_controller.py" ]; then
    echo "❌ Error: factorio_n8n_controller.py not found"
    exit 1
fi

# Create directory on NAS
echo "📁 Creating directory on NAS..."
ssh $NAS_HOST "sudo mkdir -p $NAS_PATH && sudo chmod 755 $NAS_PATH && sudo mkdir -p $NAS_PATH/logs && sudo chmod 755 $NAS_PATH/logs"

# Copy files
echo "📦 Copying files to NAS..."
scp $LOCAL_PATH/factorio_n8n_controller.py \
    $LOCAL_PATH/config.py \
    $LOCAL_PATH/requirements.txt \
    $NAS_HOST:/tmp/

# Move files to final location and update config
echo "📁 Moving files and updating config..."
ssh $NAS_HOST "sudo mv /tmp/factorio_n8n_controller.py /tmp/config.py /tmp/requirements.txt $NAS_PATH/ && \
    sudo chmod 644 $NAS_PATH/*.py $NAS_PATH/*.txt && \
    sudo sed -i 's/OLLAMA_HOST = \"localhost\"/OLLAMA_HOST = \"192.168.0.30\"/' $NAS_PATH/config.py"

echo ""
echo "✅ Files copied to NAS!"
echo ""
echo "Next steps:"
echo "1. In TrueNAS Web UI:"
echo "   - Apps → Discover Apps → ⋮ → Install via YAML"
echo "   - Application Name: factorio-controller"
echo "   - Paste contents of: $LOCAL_PATH/truenas_controller_app.yaml"
echo "   - Deploy"
echo ""
echo "2. After deployment, verify:"
echo "   ssh $NAS_HOST 'sudo docker ps | grep factorio-controller'"
echo "   ssh $NAS_HOST 'sudo docker logs factorio-n8n-controller'"
echo ""
echo "3. Test the endpoint:"
echo "   curl -X POST http://192.168.0.158:8080/execute-action \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"agent_id\": \"test\", \"action\": \"walk_to\", \"params\": {\"x\": 10, \"y\": 20}}'"

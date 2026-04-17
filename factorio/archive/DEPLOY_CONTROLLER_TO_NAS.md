# Deploy Factorio Controller to TrueNAS NAS

## Quick Deploy Script

```bash
#!/bin/bash
# deploy_controller_to_nas.sh

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
```

## Manual Deployment Steps

### 1. Prepare Files on Mac
```bash
cd /Users/pete/dotfiles/factorio
ls -la factorio_n8n_controller.py config.py requirements.txt Dockerfile.controller docker-compose.controller.yml
```

### 2. Transfer to NAS
```bash
# Create directory
ssh truenas_admin@192.168.0.158 "sudo mkdir -p /mnt/boot-pool/apps/factorio-controller"

# Copy files
scp factorio_n8n_controller.py config.py requirements.txt Dockerfile.controller docker-compose.controller.yml truenas_admin@192.168.0.158:/tmp/

# Move to final location
ssh truenas_admin@192.168.0.158 "sudo mv /tmp/*.py /tmp/*.txt /tmp/*.controller* /mnt/boot-pool/apps/factorio-controller/"
```

### 3. Update config.py for NAS
```bash
ssh truenas_admin@192.168.0.158
cd /mnt/boot-pool/apps/factorio-controller
sudo sed -i 's/OLLAMA_HOST = "localhost"/OLLAMA_HOST = "192.168.0.30"/' config.py
```

### 4. Build and Deploy
```bash
cd /mnt/boot-pool/apps/factorio-controller
sudo docker compose -f docker-compose.controller.yml build
sudo docker compose -f docker-compose.controller.yml up -d
```

### 5. Verify
```bash
# Check container is running
sudo docker ps | grep factorio-controller

# Check logs
sudo docker logs factorio-n8n-controller

# Test endpoint
curl -X POST http://localhost:8080/execute-action \
  -H "Content-Type: application/json" \
  -d '{"agent_id": "test", "action": "walk_to", "params": {"x": 10, "y": 20}}'
```

### 6. Update n8n Workflow
Change the action executor URL from:
- `http://192.168.0.30:8080/execute-action`

To:
- `http://localhost:8080/execute-action`

## Troubleshooting

### Container won't start
```bash
# Check logs
sudo docker logs factorio-n8n-controller

# Check if port 8080 is in use
sudo netstat -tuln | grep 8080
```

### Can't reach Ollama on Mac
- Verify Mac firewall allows connections from NAS
- Test: `curl http://192.168.0.30:11434/api/tags` from NAS
- Check Ollama is running: `ps aux | grep ollama` on Mac

### n8n still can't reach controller
- Verify controller is on `host` network mode
- Test from n8n container: `docker exec -it <n8n-container> curl http://localhost:8080/execute-action`
- Check if n8n is also on host network

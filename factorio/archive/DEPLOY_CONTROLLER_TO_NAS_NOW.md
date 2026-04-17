# Deploy RCON Controller to NAS - Updated Plan

## Current Status
- ✅ Controller is running on Mac (192.168.0.30:8080)
- ✅ n8n is now on host network (can reach localhost services)
- ✅ We have Docker setup ready (`Dockerfile.controller` and `docker-compose.controller.yml`)

## Why Separate Container (Not Same as Factorio)?

**Putting controller in same container as Factorio is NOT recommended because:**
1. **Separation of Concerns**: Factorio server and controller are different services
2. **Independent Scaling**: Can restart/update controller without affecting game server
3. **Resource Management**: Can limit resources separately
4. **Debugging**: Easier to debug when services are isolated
5. **Docker Best Practice**: One process per container

## Deployment Steps

### Option 1: Deploy as TrueNAS Custom App (Recommended)

1. **Prepare the YAML** - I'll create an updated docker-compose YAML for TrueNAS
2. **Import to TrueNAS**:
   - Apps → Discover Apps → ⋮ → Install via YAML
   - Application Name: `factorio-controller`
   - Paste the YAML
   - Deploy

### Option 2: Deploy via Docker Compose (SSH to NAS)

1. **SSH to NAS**:
   ```bash
   ssh truenas_admin@192.168.0.158
   ```

2. **Create directory**:
   ```bash
   sudo mkdir -p /mnt/boot-pool/apps/factorio-controller
   cd /mnt/boot-pool/apps/factorio-controller
   ```

3. **Copy files from Mac**:
   ```bash
   # From Mac:
   scp factorio_n8n_controller.py config.py requirements.txt Dockerfile.controller docker-compose.controller.yml truenas_admin@192.168.0.158:/tmp/
   
   # On NAS:
   sudo mv /tmp/*.py /tmp/*.txt /tmp/*.controller* /mnt/boot-pool/apps/factorio-controller/
   ```

4. **Update config.py** (Ollama still on Mac):
   ```bash
   sudo sed -i 's/OLLAMA_HOST = "localhost"/OLLAMA_HOST = "192.168.0.30"/' config.py
   ```

5. **Build and start**:
   ```bash
   sudo docker compose -f docker-compose.controller.yml build
   sudo docker compose -f docker-compose.controller.yml up -d
   ```

## After Deployment

1. **Update n8n workflow**: Change action executor URL from:
   - `http://192.168.0.30:8080/execute-action`
   - To: `http://localhost:8080/execute-action` (since n8n is on host network)

2. **Stop Mac controller** (optional, to avoid conflicts):
   ```bash
   # Find and stop the process
   pkill -f factorio_n8n_controller.py
   ```

3. **Test**:
   ```bash
   curl -X POST http://192.168.0.158:8080/execute-action \
     -H "Content-Type: application/json" \
     -d '{"agent_id": "test", "action": "walk_to", "params": {"x": 10, "y": 20}}'
   ```

## Benefits of Moving to NAS

1. **Always Available**: Runs on NAS, doesn't depend on Mac being on
2. **Better Network**: Same network as Factorio and n8n (localhost connections)
3. **Auto-restart**: Docker restart policies keep it running
4. **Centralized**: All Factorio-related services in one place

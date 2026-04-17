# Deploy Factorio Controller to NAS - Step by Step

## Current Status
- ✅ Controller is running on Mac (192.168.0.30:8080)
- ✅ n8n is on host network (can reach localhost:8080)
- ✅ Action executor workflow updated to use `localhost:8080`
- ✅ Files ready for deployment

## Why Separate Container (Not Same as Factorio)?

**Putting controller in same container as Factorio is NOT recommended:**
1. **Separation of Concerns**: Different services, different lifecycles
2. **Independent Restarts**: Update controller without affecting game server
3. **Resource Limits**: Can limit CPU/memory separately
4. **Debugging**: Easier to debug isolated services
5. **Docker Best Practice**: One process per container

## Deployment Method: TrueNAS Custom App (Recommended)

### Step 1: Copy Files to NAS

**Option A: Manual Copy (if SSH password required)**
```bash
# From Mac, copy files to NAS
scp factorio_n8n_controller.py config.py requirements.txt truenas_admin@192.168.0.158:/tmp/

# Then SSH to NAS and move files
ssh truenas_admin@192.168.0.158
sudo mkdir -p /mnt/boot-pool/apps/factorio-controller
sudo mv /tmp/factorio_n8n_controller.py /tmp/config.py /tmp/requirements.txt /mnt/boot-pool/apps/factorio-controller/
sudo chmod 644 /mnt/boot-pool/apps/factorio-controller/*.py /mnt/boot-pool/apps/factorio-controller/*.txt

# Update config.py for NAS environment
sudo sed -i 's/OLLAMA_HOST = "localhost"/OLLAMA_HOST = "192.168.0.30"/' /mnt/boot-pool/apps/factorio-controller/config.py
```

**Option B: Use TrueNAS Web UI File Manager**
1. Open TrueNAS Web UI → **Storage** → **Pools**
2. Navigate to `boot-pool/apps/`
3. Create folder `factorio-controller`
4. Upload files via Web UI

### Step 2: Deploy as TrueNAS Custom App

1. **Open TrueNAS Web UI**: `http://192.168.0.158`
2. **Go to Apps** → **Discover Apps**
3. **Click the three-dot menu (⋮)** in top right
4. **Select "Install via YAML"**
5. **Application Name**: `factorio-controller`
6. **Paste YAML**: Copy contents of `truenas_controller_app.yaml`
7. **Review Configuration**:
   - Verify `RCON_PASSWORD` matches your Factorio server
   - Verify volume path: `/mnt/boot-pool/apps/factorio-controller`
8. **Deploy**

### Step 3: Verify Deployment

```bash
# SSH to NAS
ssh truenas_admin@192.168.0.158

# Check container is running
sudo docker ps | grep factorio-controller

# Check logs
sudo docker logs factorio-n8n-controller

# Test endpoint
curl -X POST http://localhost:8080/execute-action \
  -H "Content-Type: application/json" \
  -d '{"agent_id": "test", "action": "walk_to", "params": {"x": 10, "y": 20}}'
```

### Step 4: Stop Mac Controller (Optional)

Once NAS controller is working, stop the Mac controller:

```bash
# Find and stop the process
pkill -f factorio_n8n_controller.py

# Or if running as service:
launchctl stop com.pete.factorio-n8n-controller
```

## Alternative: Docker Compose (If TrueNAS Custom App Doesn't Work)

If the TrueNAS Custom App method doesn't work, you can deploy via Docker Compose:

```bash
# SSH to NAS
ssh truenas_admin@192.168.0.158

# Navigate to directory
cd /mnt/boot-pool/apps/factorio-controller

# Copy docker-compose.controller.yml to NAS
# (From Mac: scp docker-compose.controller.yml truenas_admin@192.168.0.158:/mnt/boot-pool/apps/factorio-controller/)

# Build and start
sudo docker compose -f docker-compose.controller.yml build
sudo docker compose -f docker-compose.controller.yml up -d
```

## Benefits of Moving to NAS

1. **Always Available**: Runs on NAS, doesn't depend on Mac
2. **Better Network**: Same network as Factorio and n8n (localhost connections)
3. **Auto-restart**: Docker restart policies keep it running
4. **Centralized**: All Factorio services in one place
5. **Simplified**: No need to keep Mac running

## Troubleshooting

### Container won't start
- Check logs: `sudo docker logs factorio-n8n-controller`
- Verify files are in `/mnt/boot-pool/apps/factorio-controller/`
- Check permissions: `sudo ls -la /mnt/boot-pool/apps/factorio-controller/`

### Can't reach Ollama on Mac
- Verify Mac firewall allows connections from NAS
- Test: `curl http://192.168.0.30:11434/api/tags` from NAS
- Check Ollama is running on Mac

### n8n still can't reach controller
- Verify controller is on `host` network mode
- Test from n8n container: `docker exec -it <n8n-container> curl http://localhost:8080/execute-action`
- Verify n8n is also on host network

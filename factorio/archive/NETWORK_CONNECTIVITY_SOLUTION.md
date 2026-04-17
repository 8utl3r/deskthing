# Network Connectivity Solution for n8n → Python Controller

## Problem Summary

- **Issue**: n8n (running on TrueNAS NAS at 192.168.0.158:30109) cannot reach Python controller (running on Mac at 192.168.0.30:8080)
- **Error**: "The resource you are requesting could not be found" (404)
- **Evidence**: 
  - NAS can ping Mac (network connectivity works)
  - Mac can reach itself on 192.168.0.30:8080
  - NAS can reach Mac on 192.168.0.30:8080 (via SSH test)
  - But n8n container cannot reach Mac

## Root Cause Analysis

### Finding 1: Network Connectivity
✅ **NAS can reach Mac**: `ping 192.168.0.30` succeeds
✅ **Mac controller is accessible**: Direct curl from NAS works
❌ **n8n container cannot reach Mac**: Likely Docker/Kubernetes network isolation

### Finding 2: Container Networking
- n8n is running in a container on TrueNAS
- Containers may be in isolated Docker networks
- Network policies or firewall rules may block outbound connections
- Container may not have route to 192.168.0.30

### Finding 3: macOS Firewall
✅ **Firewall is disabled**: Not blocking connections
✅ **Python is permitted**: Firewall rules allow Python

## Solutions

### Solution 1: Run Python Controller on NAS (Recommended)

**Advantages:**
- Same network as n8n (localhost communication)
- No network isolation issues
- More reliable connection
- Can run 24/7 without Mac being on

**Implementation:**

1. **Create Docker container for controller:**
   ```bash
   # On NAS (via SSH or TrueNAS UI)
   cd /mnt/boot-pool/apps/factorio-controller
   
   # Copy files from Mac
   scp -r /Users/pete/dotfiles/factorio/* truenas_admin@192.168.0.158:/mnt/boot-pool/apps/factorio-controller/
   ```

2. **Deploy via Docker Compose:**
   ```bash
   # On NAS
   cd /mnt/boot-pool/apps/factorio-controller
   sudo docker compose -f docker-compose.controller.yml up -d
   ```

3. **Update n8n workflow:**
   - Change URL from `http://192.168.0.30:8080/execute-action` 
   - To: `http://localhost:8080/execute-action` (or `http://factorio-controller:8080` if in same Docker network)

4. **Ollama consideration:**
   - Option A: Keep Ollama on Mac, controller connects to `192.168.0.30:11434`
   - Option B: Run Ollama on NAS too (more complex, but fully self-contained)

### Solution 2: Use Reverse Proxy on NAS

**Advantages:**
- Keep controller on Mac
- Simple proxy setup
- Can use existing nginx/traefik on NAS

**Implementation:**

1. **Set up nginx reverse proxy on NAS:**
   ```nginx
   # /etc/nginx/sites-available/factorio-controller
   server {
       listen 8080;
       location / {
           proxy_pass http://192.168.0.30:8080;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```

2. **Update n8n workflow:**
   - Change URL to `http://localhost:8080/execute-action`

### Solution 3: Fix Container Network Configuration

**If n8n is in Docker:**

1. **Check n8n container network:**
   ```bash
   sudo docker inspect <n8n-container> | grep NetworkMode
   ```

2. **Options:**
   - Use `--network host` for n8n container (if possible)
   - Add route in container network to reach Mac
   - Use Docker's `extra_hosts` to map Mac IP

3. **If n8n is in Kubernetes:**
   - Check NetworkPolicy rules
   - Add egress rule to allow connections to 192.168.0.30:8080
   - Or use Service/Ingress to expose controller

### Solution 4: Use n8n's HTTP Request with Different Method

**Test if it's a URL parsing issue:**

1. Try using IP directly without hostname resolution
2. Try using `http://192.168.0.30:8080/execute-action` (already tried)
3. Check if n8n has proxy settings that need configuration

## Recommended Approach

**Solution 1 (Run Controller on NAS)** is recommended because:
- Simplest network setup (localhost communication)
- Most reliable (no network isolation issues)
- Better for 24/7 operation
- Controller can still connect to Ollama on Mac if needed

## Implementation Steps for Solution 1

### Step 1: Prepare Files on Mac
```bash
cd /Users/pete/dotfiles/factorio
# Files needed:
# - factorio_n8n_controller.py
# - config.py
# - requirements.txt
# - Dockerfile.controller
# - docker-compose.controller.yml
```

### Step 2: Transfer to NAS
```bash
# Create directory on NAS
ssh truenas_admin@192.168.0.158 "sudo mkdir -p /mnt/boot-pool/apps/factorio-controller"

# Copy files
scp factorio_n8n_controller.py config.py requirements.txt Dockerfile.controller docker-compose.controller.yml truenas_admin@192.168.0.158:/tmp/
ssh truenas_admin@192.168.0.158 "sudo mv /tmp/*.py /tmp/*.txt /tmp/*.controller* /mnt/boot-pool/apps/factorio-controller/"
```

### Step 3: Update config.py for NAS
```python
# On NAS, config.py should have:
OLLAMA_HOST = "192.168.0.30"  # Mac IP where Ollama runs
OLLAMA_PORT = 11434
RCON_HOST = "192.168.0.158"  # Localhost or NAS IP
```

### Step 4: Deploy Container
```bash
ssh truenas_admin@192.168.0.158
cd /mnt/boot-pool/apps/factorio-controller
sudo docker compose -f docker-compose.controller.yml up -d
```

### Step 5: Update n8n Workflow
- Change action executor URL to: `http://localhost:8080/execute-action`
- Or if using Docker network: `http://factorio-controller:8080/execute-action`

### Step 6: Test
```bash
# From NAS
curl -X POST http://localhost:8080/execute-action \
  -H "Content-Type: application/json" \
  -d '{"agent_id": "test", "action": "walk_to", "params": {"x": 10, "y": 20}}'
```

## Alternative: Keep Controller on Mac

If you prefer to keep controller on Mac:

1. **Set up SSH tunnel from NAS to Mac:**
   ```bash
   # On NAS, create persistent SSH tunnel
   ssh -N -L 8080:localhost:8080 pete@192.168.0.30
   ```

2. **Update n8n workflow to use:** `http://localhost:8080/execute-action`

3. **Or use TrueNAS reverse proxy** (if available)

## Testing Network Connectivity

### From NAS (host):
```bash
ping 192.168.0.30  # Should work
curl http://192.168.0.30:8080/execute-action  # Should work
```

### From n8n container:
```bash
# Need to exec into container
docker exec -it <n8n-container> curl http://192.168.0.30:8080/execute-action
```

## Next Steps

1. Choose solution (recommended: Solution 1)
2. Implement chosen solution
3. Update n8n workflow URLs
4. Test end-to-end: patrol workflow → action executor → Python controller → RCON
5. Verify loop continues repeating

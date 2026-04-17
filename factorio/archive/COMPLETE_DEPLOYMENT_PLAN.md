# Complete Deployment Plan: Controller to NAS

## Overview

Move the Factorio controller to NAS, add all missing actions, and ensure n8n can access it.

## Current Status

### ✅ What's Ready
1. **Controller Code**: `factorio_n8n_controller.py`
   - ✅ HTTP server for n8n
   - ✅ RCON connection management
   - ✅ **NOW: All 13 actions supported** (just added missing 9)

2. **Deployment Files**:
   - ✅ `Dockerfile.controller` - Container image
   - ✅ `docker-compose.controller.yml` - Docker Compose config
   - ✅ `truenas_controller_app.yaml` - TrueNAS Custom App YAML
   - ✅ `deploy_controller_script.sh` - Deployment script

3. **Configuration**:
   - ✅ `config.py` - Configuration file
   - ✅ `requirements.txt` - Python dependencies

4. **n8n Integration**:
   - ✅ Action executor workflow uses `localhost:8080`
   - ✅ n8n on host network (can reach localhost)

## Actions Now Supported (13 total)

### Movement & Mining
1. ✅ `walk_to` - Move to position
2. ✅ `mine_resource` - Mine resources

### Crafting & Building
3. ✅ `craft_enqueue` - Queue crafting recipes ⭐ **NEW**
4. ✅ `place_entity` - Place buildings/entities

### Machine Configuration
5. ✅ `set_entity_recipe` - Configure machine recipes ⭐ **NEW**
6. ✅ `set_entity_filter` - Set filters on inserters ⭐ **NEW**
7. ✅ `set_inventory_limit` - Set inventory limits ⭐ **NEW**

### Inventory Management
8. ✅ `set_inventory_item` - Insert items into entities
9. ✅ `get_inventory_item` - Extract items from entities ⭐ **NEW**

### Entity Management
10. ✅ `pickup_entity` - Pick up entities from world ⭐ **NEW**

### Research
11. ✅ `enqueue_research` - Queue research ⭐ **NEW**
12. ✅ `cancel_current_research` - Cancel research ⭐ **NEW**

### Exploration
13. ✅ `chart_view` - Chart chunks ⭐ **NEW**

## Deployment Steps

### Step 1: Verify Controller Code
- [x] All 13 actions added to `execute_action()`
- [ ] Test locally before deploying
- [ ] Verify error handling works

### Step 2: Prepare Files for NAS

**Files to copy to NAS:**
- `factorio_n8n_controller.py` (updated with all actions)
- `config.py`
- `requirements.txt`
- `Dockerfile.controller`
- `docker-compose.controller.yml` (optional, if using Docker Compose)
- `truenas_controller_app.yaml` (if using TrueNAS Custom App)

### Step 3: Deploy to NAS

**Option A: TrueNAS Custom App (Recommended)**
1. Copy files to NAS: `/mnt/boot-pool/apps/factorio-controller/`
2. Update `config.py`: Change `OLLAMA_HOST` to `192.168.0.30` (Mac)
3. In TrueNAS UI: Apps → Discover Apps → ⋮ → Install via YAML
4. Paste contents of `truenas_controller_app.yaml`
5. Deploy

**Option B: Docker Compose (SSH)**
1. SSH to NAS
2. Copy files to `/mnt/boot-pool/apps/factorio-controller/`
3. Update `config.py`
4. Run: `sudo docker compose -f docker-compose.controller.yml up -d`

### Step 4: Verify Deployment

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
  -d '{"agent_id":"1","action":"walk_to","params":{"x":0,"y":0}}'
```

### Step 5: Test All Actions

Test each action to ensure they work:
```bash
# Test craft_enqueue
curl -X POST http://localhost:8080/execute-action \
  -H "Content-Type: application/json" \
  -d '{"agent_id":"1","action":"craft_enqueue","params":{"recipe":"iron-gear-wheel","count":10}}'

# Test set_entity_recipe
curl -X POST http://localhost:8080/execute-action \
  -H "Content-Type: application/json" \
  -d '{"agent_id":"1","action":"set_entity_recipe","params":{"entity":"assembling-machine-1","x":10,"y":10,"recipe":"iron-gear-wheel}}'

# ... test all 13 actions
```

### Step 6: Update n8n (if needed)

- ✅ Action executor already uses `localhost:8080` (correct)
- ⚠️ Update any workflows that need new actions
- ⚠️ Test end-to-end: n8n → controller → Factorio

### Step 7: Stop Mac Controller

Once NAS controller is working:
```bash
# On Mac
pkill -f factorio_n8n_controller.py

# Or if running as service
launchctl stop com.pete.factorio-n8n-controller
```

## Network Architecture

```
n8n (NAS, host network)
  ↓ HTTP POST localhost:8080
Controller (NAS, host network)
  ↓ RCON TCP 192.168.0.158:27015
Factorio Server (NAS)
```

**Benefits:**
- ✅ All services on same host (localhost communication)
- ✅ No network isolation issues
- ✅ Controller always available (doesn't depend on Mac)

## Configuration

### Controller Config (`config.py`)
```python
RCON_HOST = "192.168.0.158"  # Factorio on same NAS
RCON_PORT = 27015
RCON_PASSWORD = "Sahb5aevu3neiph"  # Update if different
OLLAMA_HOST = "192.168.0.30"  # Mac IP (if still using Mac Ollama)
OLLAMA_PORT = 11434
```

### Docker Config (`truenas_controller_app.yaml`)
- `network_mode: host` - So n8n can reach at localhost:8080
- Volume: `/mnt/boot-pool/apps/factorio-controller:/app`
- Environment: RCON settings, Ollama settings

## API Reference for n8n

All actions use the same endpoint:
```
POST http://localhost:8080/execute-action
Content-Type: application/json

{
  "agent_id": "1",
  "action": "action_name",
  "params": {...}
}
```

### Action Parameters

See `CONTROLLER_API_REFERENCE.md` for complete parameter documentation.

## Troubleshooting

### Container won't start
- Check logs: `sudo docker logs factorio-n8n-controller`
- Verify files are in correct location
- Check permissions

### n8n can't reach controller
- Verify controller is on `host` network mode
- Test: `curl http://localhost:8080/health` from NAS
- Check n8n is also on host network

### Actions fail
- Check RCON connection: `curl http://localhost:8080/health`
- Verify Factorio server is running
- Check action parameters match API reference

## Success Criteria

- [ ] Controller running on NAS
- [ ] All 13 actions working
- [ ] n8n can reach controller at `localhost:8080`
- [ ] End-to-end test passes
- [ ] Mac controller stopped

## Next Steps After Deployment

1. **Documentation**: Create API reference for all actions
2. **Testing**: Test all 13 actions with real Factorio agents
3. **Workflows**: Update n8n workflows to use new actions
4. **Monitoring**: Set up health checks and logging

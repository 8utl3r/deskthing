# Controller Deployment Checklist

## ✅ What We Have

1. **Controller Code**: `factorio_n8n_controller.py`
   - ✅ HTTP server for n8n
   - ✅ RCON connection management
   - ⚠️ Only 4 actions supported (need to add 9 more)

2. **Deployment Files**:
   - ✅ `Dockerfile.controller` - Container image
   - ✅ `docker-compose.controller.yml` - Docker Compose config
   - ✅ `truenas_controller_app.yaml` - TrueNAS Custom App YAML
   - ✅ `deploy_controller_script.sh` - Deployment script

3. **Configuration**:
   - ✅ `config.py` - Configuration file
   - ✅ `requirements.txt` - Python dependencies

4. **n8n Integration**:
   - ✅ Action executor workflow updated to use `localhost:8080`
   - ✅ n8n on host network (can reach localhost)

## ❌ What's Missing

### 1. **Missing Actions** (9 actions need to be added)
- ❌ `craft_enqueue` - Queue crafting recipes
- ❌ `set_entity_recipe` - Configure machines
- ❌ `get_inventory_item` - Extract items
- ❌ `set_entity_filter` - Set filters
- ❌ `set_inventory_limit` - Set limits
- ❌ `pickup_entity` - Pick up entities
- ❌ `enqueue_research` - Queue research
- ❌ `cancel_current_research` - Cancel research
- ❌ `chart_view` - Chart chunks

### 2. **Documentation**
- ⚠️ Need to document all supported actions
- ⚠️ Need API documentation for n8n workflows

## 📋 Deployment Steps

### Step 1: Add Missing Actions to Controller
- [ ] Add `craft_enqueue` action
- [ ] Add `set_entity_recipe` action
- [ ] Add `get_inventory_item` action
- [ ] Add `set_entity_filter` action
- [ ] Add `set_inventory_limit` action
- [ ] Add `pickup_entity` action
- [ ] Add `enqueue_research` action
- [ ] Add `cancel_current_research` action
- [ ] Add `chart_view` action
- [ ] Test all actions

### Step 2: Deploy to NAS
- [ ] Copy files to NAS
- [ ] Update config.py for NAS environment
- [ ] Deploy as TrueNAS Custom App OR Docker Compose
- [ ] Verify container is running
- [ ] Test HTTP endpoint

### Step 3: Update n8n
- [ ] Verify action executor workflow uses `localhost:8080`
- [ ] Test end-to-end: n8n → controller → Factorio
- [ ] Update any workflows that need new actions

### Step 4: Documentation
- [ ] Document all supported actions
- [ ] Create API reference for n8n workflows
- [ ] Update deployment guide

## 🎯 Priority Order

1. **High Priority Actions** (add first):
   - `craft_enqueue` - Essential for crafting
   - `set_entity_recipe` - Essential for automation
   - `get_inventory_item` - Essential for item extraction

2. **Medium Priority Actions**:
   - `set_entity_filter` - Useful for automation
   - `pickup_entity` - Useful for cleanup

3. **Low Priority Actions**:
   - `set_inventory_limit` - Nice to have
   - `enqueue_research` - Nice to have
   - `cancel_current_research` - Nice to have
   - `chart_view` - Nice to have

## ✅ Success Criteria

- [ ] All 13 actions supported
- [ ] Controller running on NAS
- [ ] n8n can reach controller at `localhost:8080`
- [ ] End-to-end test passes
- [ ] Documentation complete

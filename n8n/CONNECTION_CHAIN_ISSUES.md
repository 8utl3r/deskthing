# Connection Chain Issues Found

## The Full Chain

```
Patrol Workflow (n8n)
  ↓ HTTP POST
Factorio Action Executor Workflow (n8n) 
  ↓ HTTP POST  
Python Controller (localhost:8080)
  ↓ RCON
Factorio Server
```

## Issues Found

### 1. ❌ Factorio Action Executor Workflow Missing
**Status**: Workflow doesn't exist in n8n
**Error**: `404 - The requested webhook "POST factorio-action-executor" is not registered`
**Fix**: Need to import/create the workflow

### 2. ⚠️ Webhook Path Mismatch  
**Issue**: Workflow file has `"path": "factorio-action"` but patrol workflow calls `factorio-action-executor`
**Fix**: Updated workflow file to use `factorio-action-executor`

### 3. ❌ Python Controller Not Running
**Status**: `localhost:8080` is not responding
**Error**: Connection refused
**Fix**: Need to start `factorio_n8n_controller.py`

### 4. ⚠️ Patrol Workflow Response
**Status**: Response is empty (separate issue we've been debugging)
**Note**: This is a different issue from the RCON connection

## What's Actually Broken

**The RCON connection chain is broken at multiple points**:

1. **Factorio Action Executor workflow** - Doesn't exist in n8n (needs to be imported/created)
2. **Python Controller** - Not running (needs to be started)
3. **Patrol Workflow Response** - Empty response (separate issue)

## Fixes Applied

1. ✅ Fixed webhook path in `factorio_action_executor.json` (changed from `factorio-action` to `factorio-action-executor`)
2. ✅ Added `httpMethod: "POST"` to webhook node
3. ⏳ Creating/importing workflow into n8n
4. ⏳ Activating workflow
5. ⏳ Need to start Python controller

## Next Steps

1. **Import Factorio Action Executor workflow** into n8n
2. **Activate the workflow**
3. **Start Python controller**: `python factorio_n8n_controller.py`
4. **Test the chain**: 
   ```bash
   curl -X POST http://192.168.0.158:30109/webhook/factorio-action-executor \
     -H "Content-Type: application/json" \
     -d '{"agent_id": "1", "action": "walk_to", "params": {"x": 0, "y": 0}}'
   ```

## Testing the Chain

### Step 1: Test Factorio Action Executor Webhook
```bash
curl -X POST http://192.168.0.158:30109/webhook/factorio-action-executor \
  -H "Content-Type: application/json" \
  -d '{"agent_id": "1", "action": "walk_to", "params": {"x": 0, "y": 0}}'
```
**Expected**: Should call Python controller (will fail if controller not running)

### Step 2: Test Python Controller Directly
```bash
curl -X POST http://localhost:8080/execute-action \
  -H "Content-Type: application/json" \
  -d '{"agent_id": "1", "action": "walk_to", "params": {"x": 0, "y": 0}}'
```
**Expected**: Should execute RCON command (will fail if Factorio server not running or RCON not connected)

### Step 3: Test Full Chain
```bash
curl -X POST http://192.168.0.158:30109/webhook/patrol-square \
  -H "Content-Type: application/json" \
  -d '{"agent_id": "1", "params": {"center_x": 0, "center_y": 0, "radius": 30}}'
```
**Expected**: Should trigger patrol, which calls action executor, which calls Python controller, which executes RCON

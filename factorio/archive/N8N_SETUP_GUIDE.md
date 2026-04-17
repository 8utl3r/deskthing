# n8n Setup Guide for Factorio NPC Control

## Overview

This guide shows how to set up n8n workflows for Factorio NPC control. The Python controller becomes a simple bridge that:
1. Gets game state
2. Asks LLM which workflow to run
3. Triggers n8n workflow via webhook
4. Provides HTTP endpoint for n8n to execute RCON actions

## Architecture

```
Python Controller (localhost:8080)
  ↓ (HTTP webhook)
n8n Workflows (192.168.0.158:30109)
  ↓ (HTTP request)
Python Controller (localhost:8080/execute-action)
  ↓ (RCON)
Factorio Server
```

## Setup Steps

### 1. Import n8n Workflows

1. Open n8n at `http://192.168.0.158:30109`
2. Go to **Workflows** → **Add workflow** → **Import from File**
3. Import these workflows (in order):
   - `factorio_action_executor.json` - Executes RCON actions
   - `factorio_gather_resource.json` - Gathers resources
   - (More workflows to come)

### 2. Configure Workflow URLs

Each workflow needs to know where to call the Python controller:

1. Open each workflow in n8n
2. Find HTTP Request nodes that call `http://localhost:8080`
3. Update to your actual Python controller URL (if different)
4. Save and activate workflows

### 3. Start Python Controller

```bash
cd /Users/pete/dotfiles/factorio
python factorio_n8n_controller.py
```

The controller will:
- Start HTTP server on `localhost:8080` for n8n to call
- Connect to Factorio RCON
- Start Ollama (if not running)
- Begin the control loop

### 4. Test Workflow

Test a workflow manually:
```bash
curl -X POST http://192.168.0.158:30109/webhook/gather-resource \
  -H "Content-Type: application/json" \
  -d '{"agent_id": "1", "params": {"resource_name": "iron-ore"}}'
```

## Workflow Structure

### Action Executor Workflow
**Purpose**: Execute individual RCON actions

**Webhook**: `factorio-action-executor`
**Input**: 
```json
{
  "agent_id": "1",
  "action": "walk_to",
  "params": {"x": 10, "y": 10}
}
```

**Output**:
```json
{
  "success": true,
  "message": "Action walk_to executed successfully"
}
```

### Gather Resource Workflow
**Purpose**: Complete resource gathering task

**Webhook**: `gather-resource`
**Input**:
```json
{
  "agent_id": "1",
  "params": {"resource_name": "iron-ore"}
}
```

**Steps**:
1. Get reachable entities
2. Find resource
3. Walk to resource (via Action Executor)
4. Mine resource (via Action Executor)
5. Return success/failure

## Benefits

✅ **Visual debugging** - See workflow execution in n8n UI  
✅ **Easy modification** - Edit workflows without code changes  
✅ **Reusable** - Share workflows between agents  
✅ **Error handling** - n8n's built-in error handling  
✅ **Learn n8n** - Practice while building NPC system  

## Next Steps

1. Create more workflows:
   - `build_blueprint.json`
   - `defend_base.json`
   - `build_chest_and_fill.json`
   - `patrol.json`

2. Add error handling and retries in n8n

3. Add workflow monitoring and logging

4. Create workflow templates for common patterns

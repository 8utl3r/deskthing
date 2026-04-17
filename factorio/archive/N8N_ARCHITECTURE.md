# Factorio NPC Control with n8n

## Architecture Overview

```
LLM (Ollama) ←→ Python Controller ←→ n8n Workflows ←→ Factorio RCON
```

**Flow:**
1. Python controller gets game state
2. Python asks LLM: "Which workflow should I run?"
3. Python triggers n8n workflow via webhook
4. n8n workflow executes (calls Python for RCON actions)
5. Python executes RCON commands
6. n8n workflow reports result back to Python
7. Python reports result to LLM for next decision

## Benefits

✅ **Visual workflow design** - See and edit workflows in n8n UI  
✅ **Easy debugging** - Watch workflow execution in real-time  
✅ **Reusable workflows** - Share workflows between agents  
✅ **Better error handling** - n8n's built-in error handling  
✅ **Learn n8n** - Practice while building NPC system  

## Components

### 1. Python Controller (Simplified)
- Gets game state from Factorio
- Queries LLM for workflow choice
- Triggers n8n workflows via HTTP webhook
- Executes RCON commands (called by n8n)
- Reports results back to LLM

### 2. n8n Workflows
Each workflow handles one task:
- **gather_resource** - Mine resource and store in chest
- **build_blueprint** - Build ghost entity
- **defend_base** - Move to enemy and engage
- **build_chest_and_fill** - Gather wood, build chest, fill it
- **patrol** - Walk in circles

### 3. n8n Action Executor
A single workflow that executes RCON actions:
- Receives action requests from other workflows
- Executes RCON commands
- Waits for completion
- Returns results

## n8n Workflow Structure

### Main Decision Workflow
**Trigger**: HTTP Webhook (from Python)
**Input**: Game state, agent state, reachable entities
**Output**: Workflow choice + parameters

### Task Workflows
Each task workflow:
1. Receives parameters from main workflow
2. Calls Action Executor for each step
3. Waits for completion
4. Reports success/failure

### Action Executor Workflow
**Trigger**: HTTP Webhook (from task workflows)
**Input**: Action name, parameters, agent_id
**Output**: Success/failure, result message

## Python Controller Changes

The controller becomes much simpler:
- No workflow logic (moved to n8n)
- Just: get state → ask LLM → trigger n8n → report result
- Provides HTTP endpoint for n8n to call for RCON actions

## n8n Instance

- **URL**: `http://192.168.0.158:30109`
- **Location**: TrueNAS Scale NAS
- **Workflows**: Stored in `/Users/pete/dotfiles/n8n/workflows/`

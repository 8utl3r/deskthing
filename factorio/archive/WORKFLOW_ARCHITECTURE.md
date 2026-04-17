# Factorio NPC Workflow Architecture

## Overview

The NPC controller now uses a **workflow-based architecture** where:
- **99% of actions are programmatic** - handled by reusable workflow scripts
- **LLM only chooses workflows** - decides which high-level task to run
- **Workflows execute automatically** - handle all the details (walking, mining, building, etc.)

## Architecture Benefits

1. **Simpler LLM decisions** - LLM just picks a workflow + parameters, not individual actions
2. **Reusable code** - Common tasks (gather, build, defend) are scripts, not LLM instructions
3. **Faster execution** - No LLM needed for every step, just for high-level choices
4. **Better reliability** - Workflows are tested code, not LLM-generated actions
5. **Chat support** - NPCs can communicate with players via in-game chat

## Available Workflows

### 1. `gather_resource`
**Purpose**: Mine a resource and store it in a chest

**Parameters**:
- `resource_name`: "iron-ore", "copper-ore", "coal", "stone"
- `count`: Optional amount to mine (omit to mine until depleted)

**What it does**:
1. Finds the resource in reachable area
2. Walks to resource
3. Mines the resource
4. Finds nearest chest
5. Walks to chest
6. Deposits items in chest

**Example**:
```json
{"workflow": "gather_resource", "params": {"resource_name": "iron-ore"}}
```

### 2. `build_blueprint`
**Purpose**: Build a ghost entity (blueprint)

**Parameters**:
- `ghost_entity`: Ghost entity dict from reachable.ghosts (has name and position)
- OR `ghost_position`: {"x": 100, "y": 100} and `entity_name`: "assembling-machine-1"

**What it does**:
1. Extracts entity name from ghost (removes "entity-ghost-" prefix)
2. Walks to ghost position
3. Places the entity

**Example**:
```json
{"workflow": "build_blueprint", "params": {"ghost_entity": reachable.ghosts[0]}}
```

### 3. `defend_base`
**Purpose**: Move to enemy and engage in combat

**Parameters**:
- `enemy`: Enemy entity dict from reachable.enemies (has name and position)
- OR `enemy_position`: {"x": 150, "y": 200}

**What it does**:
1. Walks to enemy position
2. Agent auto-attacks when in range

**Example**:
```json
{"workflow": "defend_base", "params": {"enemy": reachable.enemies[0]}}
```

### 4. `patrol`
**Purpose**: Walk in a circle around a center point

**Parameters**:
- `center`: {"x": 0, "y": 0} - center point (default: spawn)
- `radius`: 50 - circle radius in tiles (default: 50)

**What it does**:
1. Calculates next point on circle
2. Walks to that point
3. Increments angle for next patrol step

**Example**:
```json
{"workflow": "patrol", "params": {"center": {"x": 0, "y": 0}, "radius": 50}}
```

### 5. `chat`
**Purpose**: Send a message to players in-game

**Parameters**:
- `message`: Text to send
- `agent_name`: Optional name prefix (default: agent's redshirt name)

**What it does**:
1. Formats message with agent name
2. Sends via `game.print()` in Factorio
3. Message appears in-game chat

**Example**:
```json
{"workflow": "chat", "params": {"message": "I'm gathering iron ore!", "agent_name": "Lee_Kelso"}}
```

## How It Works

### LLM Decision Flow

1. **Agent is idle** → Controller checks if agent is busy
2. **Get game state** → Retrieves agent state, reachable entities, resources
3. **Ask LLM** → "Which workflow should I run?" (with context)
4. **LLM responds** → `{"workflow": "gather_resource", "params": {"resource_name": "iron-ore"}}`
5. **Execute workflow** → Workflow runs programmatically (no LLM needed)
6. **Report result** → Workflow result sent back to LLM for next decision
7. **Wait for completion** → Agent becomes idle, repeat from step 1

### Workflow Execution

Workflows are Python classes that:
- Take `controller`, `agent_id`, and `params`
- Execute a sequence of actions programmatically
- Return `{"success": bool, "message": str}`
- Handle all error cases and edge cases

### Example: gather_resource Workflow

```python
def execute(self, controller, agent_id: str, params: Dict) -> Dict:
    # 1. Find resource
    reachable = controller.get_reachable_entities(agent_id)
    target_resource = find_resource(reachable, params['resource_name'])
    
    # 2. Walk to resource
    controller.execute_action(agent_id, 'walk_to', target_pos)
    wait_for_agent_idle(controller, agent_id)
    
    # 3. Mine resource
    controller.execute_action(agent_id, 'mine_resource', params)
    wait_for_agent_idle(controller, agent_id)
    
    # 4. Find chest and store
    chest = find_nearest_chest(reachable)
    controller.execute_action(agent_id, 'walk_to', chest_pos)
    wait_for_agent_idle(controller, agent_id)
    controller.execute_action(agent_id, 'set_inventory_item', {...})
    
    return {'success': True, 'message': 'Gathered iron-ore'}
```

## LLM Context Simplification

### Before (Action-based)
- LLM had to understand: walk_to, mine_resource, place_entity, set_inventory_item
- LLM had to sequence actions correctly
- LLM had to handle errors and edge cases
- Context was 10,000+ characters

### After (Workflow-based)
- LLM only needs to understand: 5 workflows
- LLM just picks workflow + parameters
- Workflows handle sequencing and errors
- Context is ~3,000 characters

## Adding New Workflows

To add a new workflow:

1. Create a class in `workflows.py`:
```python
class MyNewWorkflow(Workflow):
    def __init__(self):
        super().__init__(
            name="my_workflow",
            description="Does something useful"
        )
    
    def execute(self, controller, agent_id: str, params: Dict) -> Dict:
        # Your workflow logic here
        return {'success': True, 'message': 'Done!'}
```

2. Register it in `WORKFLOWS` dict:
```python
WORKFLOWS = {
    ...
    'my_workflow': MyNewWorkflow(),
}
```

3. Update LLM system prompt (automatic via `list_workflows()`)

## Chat Communication

NPCs can now chat with players using the `chat` workflow:

```json
{"workflow": "chat", "params": {"message": "Hello! I'm gathering resources."}}
```

Messages appear in-game via `game.print()`. The LLM can use this for:
- Status updates ("I'm defending the base!")
- Responses to player questions
- Random personality/roleplay
- Coordination with other NPCs

## Benefits Summary

✅ **99% programmatic** - Most actions don't need LLM  
✅ **Faster decisions** - LLM only chooses workflows, not every action  
✅ **More reliable** - Workflows are tested code  
✅ **Easier to extend** - Add new workflows without changing LLM prompts  
✅ **Chat support** - NPCs can communicate with players  
✅ **Simpler context** - LLM sees less, understands more  

## Files

- `workflows.py` - Workflow definitions
- `factorio_ollama_npc_controller.py` - Controller (uses workflows)
- `WORKFLOW_ARCHITECTURE.md` - This document

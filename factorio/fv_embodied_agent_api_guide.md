# FV Embodied Agent Mod - Complete API Guide

## Overview

**FV Embodied Agent** is a Factorio mod (v0.1.3) that provides programmatic control of character agents. It's designed for LLM integration and external control via RCON.

**Source**: https://github.com/hrshtt/FactoryVerse/tree/main/src/fv_embodied_agent  
**Mod Portal**: https://mods.factorio.com/mod/fv_embodied_agent

---

## Remote Interface System

### Main Interfaces

1. **`"agent"`** - Admin interface for agent lifecycle management
2. **`"agent_<id>"`** - Per-agent interface (e.g., `"agent_1"`, `"agent_2"`) for individual agent control
3. **`"admin"`** - Testing API interface (uses `Agents.testing_api`)
4. **`"custom_events"`** - Event system interface

---

## Agent Lifecycle Management (`"agent"` interface)

### Create Agents

```lua
-- Create multiple agents at once
remote.call("agent", "create_agents", count)
-- Returns: {agent_ids = {1, 2, 3, ...}}

-- Example: Create 3 agents
remote.call("agent", "create_agents", 3)
-- Creates agent_1, agent_2, agent_3
```

**Note**: The function is `create_agents` (plural), not `create_agent` (singular).

### List Agents

```lua
-- Get list of all agent IDs
remote.call("agent", "list_agents")
-- Returns: {agent_ids = {1, 2, 3}}
```

### Remove Agents

```lua
-- Remove an agent
remote.call("agent", "remove_agent", agent_id)
```

---

## Per-Agent Interface (`"agent_<id>"`)

Each agent gets its own remote interface: `agent_1`, `agent_2`, etc.

### Async Actions (Return immediately, completion via UDP)

These actions return immediately with a status, and completion is notified via UDP.

#### Movement

```lua
-- Walk to a position (pathfinding with obstacle avoidance)
remote.call("agent_1", "walk_to", {x = 100, y = 200})
-- Optional: strict_goal (boolean), options (table)
remote.call("agent_1", "walk_to", {x = 100, y = 200}, true, {max_distance = 50})

-- Returns: {queued = true, action_id = "walk_abc123"}
-- Completion sent via UDP when agent arrives
```

#### Mining

```lua
-- Mine a resource (incremental: mine 50 iron ore)
remote.call("agent_1", "mine_resource", "iron-ore", 50)

-- Mine until depleted (no count specified)
remote.call("agent_1", "mine_resource", "iron-ore")

-- Returns: {queued = true, action_id = "mine_xyz789"}
-- Completion sent via UDP when mining finishes
```

#### Crafting

```lua
-- Queue hand-crafting recipe
remote.call("agent_1", "craft_enqueue", "iron-gear-wheel", 20)
-- Agent crafts automatically when ingredients are available

-- Returns: {queued = true, action_id = "craft_def456"}
-- Completion sent via UDP when crafting finishes
```

### Synchronous Actions (Complete immediately)

These actions complete immediately and return results.

#### Entity Placement

```lua
-- Place an entity
remote.call("agent_1", "place_entity", "assembling-machine-1", {x = 105, y = 205})
-- Returns: {success = true, entity = {...}} or {success = false, error = "..."}
```

#### Machine Configuration

```lua
-- Set machine recipe
remote.call("agent_1", "set_entity_recipe", "assembling-machine-1", {x = 105, y = 205}, "iron-gear-wheel")

-- Set entity filter (inserters, containers)
remote.call("agent_1", "set_entity_filter", "fast-inserter", {x = 12, y = 10}, "inserter_stack_filter", 1, "iron-plate")

-- Set inventory limit
remote.call("agent_1", "set_inventory_limit", "chest", {x = 10, y = 10}, "chest", 10)
```

#### Inventory Management

```lua
-- Get items from entity inventory
remote.call("agent_1", "get_inventory_item", "assembling-machine-1", {x = 10, y = 10}, "assembling_machine_output", "iron-gear-wheel", 50)

-- Insert items into entity inventory
remote.call("agent_1", "set_inventory_item", "assembling-machine-1", {x = 10, y = 10}, "assembling_machine_input", "iron-plate", 100)
```

#### Entity Pickup

```lua
-- Pick up an entity from the world
remote.call("agent_1", "pickup_entity", "iron-ore", {x = 50, y = 50})
```

#### Research

```lua
-- Enqueue research
remote.call("agent_1", "enqueue_research", "automation")

-- Cancel current research
remote.call("agent_1", "cancel_current_research")
```

#### Charting

```lua
-- Chart chunks within agent's view
remote.call("agent_1", "chart_view", true)  -- true = rechart existing chunks
```

### Query Methods

#### Inspect Agent State

```lua
-- Get basic agent state
remote.call("agent_1", "inspect")
-- Returns: {agent_id = 1, position = {x, y}, force = "player"}

-- Get detailed state including activity state
remote.call("agent_1", "inspect", true)
-- Returns: {
--   agent_id = 1,
--   position = {x, y},
--   state = {
--     walking = {active = true, goal = {x, y}, progress = 0.5},
--     mining = {active = false},
--     crafting = {active = true, recipe = "iron-gear-wheel", queue = {...}}
--   }
-- }
```

#### Get Reachable Entities

```lua
-- Find all entities and resources within reach
remote.call("agent_1", "get_reachable")
-- Returns: {
--   entities = {
--     {name = "assembling-machine-1", position = {x, y}, recipe = "...", inventory = {...}},
--     ...
--   },
--   resources = {
--     {name = "iron-ore", position = {x, y}, amount = 1000},
--     ...
--   }
-- }
```

#### Get Placement Cues

```lua
-- Get placement hints and requirements for entities
remote.call("agent_1", "get_placement_cues", "assembling-machine-1")
-- Returns: {can_place = true, requirements = {...}, hints = {...}}
```

#### Get Recipes

```lua
-- Query available recipes for agent's force
remote.call("agent_1", "get_recipes")
-- Returns: {recipes = {"iron-gear-wheel", "copper-cable", ...}}
```

#### Get Technologies

```lua
-- Get all technologies
remote.call("agent_1", "get_technologies")
-- Returns: {technologies = {...}}

-- Get only available (researched) technologies
remote.call("agent_1", "get_technologies", true)
```

---

## State Machines

The mod tracks agent activities via built-in state machines:

- **Walking State Machine**: Tracks pathfinding progress, waypoint completion, arrival
- **Mining State Machine**: Tracks mining progress, entity depletion, item collection
- **Crafting State Machine**: Tracks queued recipes and completion status

All state machines send UDP notifications for action lifecycle events:
- `queued` - Action was queued
- `progress` - Action progress update
- `completed` - Action completed successfully
- `cancelled` - Action was cancelled

**UDP Port**: 34202 (default, configurable per-agent)

---

## Events

### Custom Events

The mod raises events that can be subscribed to:

- `on_agent_created` - Fired when an agent is created
- `on_agent_removed` - Fired when an agent is removed
- `on_chunk_charted` - Fired when agent charts a chunk

---

## Python RCON Usage

### Creating Agents

```python
from factorio_rcon import RCONClient

rcon = RCONClient("192.168.0.158", 27015, "password")
rcon.connect()

# Create 3 agents
response = rcon.send_command("/sc return remote.call('agent', 'create_agents', 3)")
# Returns: {agent_ids = {1, 2, 3}}

# Create a single agent (count = 1)
response = rcon.send_command("/sc return remote.call('agent', 'create_agents', 1)")
```

### Controlling Agents

```python
# Walk to position
rcon.send_command("/sc remote.call('agent_1', 'walk_to', {x=100, y=200})")

# Mine resource
rcon.send_command("/sc remote.call('agent_1', 'mine_resource', 'iron-ore', 50)")

# Craft item
rcon.send_command("/sc remote.call('agent_1', 'craft_enqueue', 'iron-gear-wheel', 20)")

# Get agent state
rcon.send_command("/sc return remote.call('agent_1', 'inspect', true)")

# Get reachable entities
rcon.send_command("/sc return remote.call('agent_1', 'get_reachable')")
```

---

## Important Notes

1. **Interface Names**:
   - Admin: `"agent"` (not `"fv_embodied_agent"`)
   - Per-agent: `"agent_<id>"` (e.g., `"agent_1"`)

2. **Function Names**:
   - `create_agents` (plural) - creates multiple agents
   - Not `create_agent` (singular)

3. **Async vs Sync**:
   - Async actions (walk_to, mine_resource, craft_enqueue) return immediately
   - Completion notifications sent via UDP
   - Sync actions (place_entity, set_entity_recipe) complete immediately

4. **State Queries**:
   - Use `inspect(true)` for detailed state including activity tracking
   - Use `get_reachable()` for finding entities and resources
   - Use `get_recipes()` and `get_technologies()` for available options

5. **UDP Notifications**:
   - Actions send UDP notifications on port 34202 (default)
   - Can be configured per-agent
   - Useful for tracking action completion externally

---

## Example: Complete Agent Workflow

```python
# 1. Create agent
rcon.send_command("/sc return remote.call('agent', 'create_agents', 1)")

# 2. Get agent state
state = rcon.send_command("/sc return remote.call('agent_1', 'inspect', true)")

# 3. Find resources
reachable = rcon.send_command("/sc return remote.call('agent_1', 'get_reachable')")

# 4. Walk to resource
rcon.send_command("/sc remote.call('agent_1', 'walk_to', {x=50, y=50})")
# Wait for UDP notification or poll state

# 5. Mine resource
rcon.send_command("/sc remote.call('agent_1', 'mine_resource', 'iron-ore', 100)")

# 6. Craft item
rcon.send_command("/sc remote.call('agent_1', 'craft_enqueue', 'iron-gear-wheel', 20)")

# 7. Place entity
rcon.send_command("/sc remote.call('agent_1', 'place_entity', 'assembling-machine-1', {x=10, y=10})")

# 8. Configure machine
rcon.send_command("/sc remote.call('agent_1', 'set_entity_recipe', 'assembling-machine-1', {x=10, y=10}, 'iron-gear-wheel')")
```

---

## Integration with LLMs

The mod is designed for LLM integration:

1. **Observe**: Use `inspect(true)` and `get_reachable()` to get game state
2. **Think**: Send state to LLM for decision-making
3. **Act**: Execute actions via remote interface
4. **Monitor**: Track action completion via UDP or polling `inspect()`

The rich query methods (`get_reachable()`, `get_recipes()`, `get_technologies()`) provide comprehensive game state for LLM decision-making.

# FV Embodied Agent API - Quick Reference

## Key Findings from Documentation Review

### Interface Names
- ✅ **`"agent"`** - Admin interface (create_agents, list_agents, remove_agent)
- ✅ **`"agent_<id>"`** - Per-agent interface (agent_1, agent_2, etc.)
- ❌ **NOT** `"fv_embodied_agent"` - This doesn't exist

### Creating Agents
```python
# Correct: create_agents (plural) with count
remote.call("agent", "create_agents", 1)  # Creates agent_1
remote.call("agent", "create_agents", 3)  # Creates agent_1, agent_2, agent_3

# Returns: {agent_ids = {1, 2, 3}}
```

### Getting Agent State
```python
# Use inspect(true) for detailed state
remote.call("agent_1", "inspect", true)
# Returns: {agent_id, position, state: {walking, mining, crafting}}
```

### Getting Game Context
```python
# Get reachable entities/resources (very useful for LLM)
remote.call("agent_1", "get_reachable")
# Returns: {entities = [...], resources = [...]}

# Get available recipes
remote.call("agent_1", "get_recipes")

# Get technologies
remote.call("agent_1", "get_technologies")
```

### Actions

**Async (return immediately, completion via UDP):**
- `walk_to({x, y})` - Movement
- `mine_resource(resource_name, count?)` - Mining
- `craft_enqueue(recipe_name, count?)` - Crafting

**Sync (complete immediately):**
- `place_entity(entity_name, {x, y})` - Place entity
- `set_entity_recipe(...)` - Configure machine
- `set_entity_filter(...)` - Set filters
- `get_inventory_item(...)` - Get items
- `set_inventory_item(...)` - Insert items

### Ollama Connection

**NOT MCP** - It's an HTTP API:
- Server: `http://localhost:11434`
- Endpoint: `/api/chat`
- Python library: `ollama` package (makes HTTP requests)
- Connection: Direct HTTP, not MCP protocol

## Updated Controller

The controller has been updated to:
1. Use `create_agents` (plural) API
2. Use `inspect(true)` for agent state
3. Use `get_reachable()` for game context
4. Support all documented action types
5. Provide rich context to LLM for better decisions

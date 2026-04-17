# Missing Actions in Controller

## Currently Supported (4 actions)
1. ✅ `walk_to` - Movement
2. ✅ `mine_resource` - Mining
3. ✅ `place_entity` - Place buildings/entities
4. ✅ `set_inventory_item` - Insert items into entities

## Missing Actions (Available in FV Embodied Agent Mod)

### Critical Actions

#### 1. `craft_enqueue` - ⚠️ **MISSING - VERY IMPORTANT**
```lua
remote.call("agent_1", "craft_enqueue", "iron-gear-wheel", 20)
```
**Purpose**: Queue hand-crafting recipes  
**Why Important**: Agents need to craft items from resources  
**Status**: ❌ Not implemented

#### 2. `set_entity_recipe` - ⚠️ **MISSING - IMPORTANT**
```lua
remote.call("agent_1", "set_entity_recipe", "assembling-machine-1", {x=105, y=205}, "iron-gear-wheel")
```
**Purpose**: Configure machines with recipes  
**Why Important**: Set up automation  
**Status**: ❌ Not implemented

#### 3. `get_inventory_item` - ⚠️ **MISSING - IMPORTANT**
```lua
remote.call("agent_1", "get_inventory_item", "assembling-machine-1", {x=10, y=10}, "assembling_machine_output", "iron-gear-wheel", 50)
```
**Purpose**: Extract items from entity inventories  
**Why Important**: Get items from machines/chests  
**Status**: ❌ Not implemented

### Useful Actions

#### 4. `set_entity_filter` - ⚠️ **MISSING**
```lua
remote.call("agent_1", "set_entity_filter", "fast-inserter", {x=12, y=10}, "inserter_stack_filter", 1, "iron-plate")
```
**Purpose**: Set filters on inserters/containers  
**Status**: ❌ Not implemented

#### 5. `set_inventory_limit` - ⚠️ **MISSING**
```lua
remote.call("agent_1", "set_inventory_limit", "chest", {x=10, y=10}, "chest", 10)
```
**Purpose**: Set inventory limits  
**Status**: ❌ Not implemented

#### 6. `pickup_entity` - ⚠️ **MISSING**
```lua
remote.call("agent_1", "pickup_entity", "iron-ore", {x=50, y=50})
```
**Purpose**: Pick up entities from the world  
**Status**: ❌ Not implemented

#### 7. `enqueue_research` - ⚠️ **MISSING**
```lua
remote.call("agent_1", "enqueue_research", "automation")
```
**Purpose**: Queue research  
**Status**: ❌ Not implemented

#### 8. `cancel_current_research` - ⚠️ **MISSING**
```lua
remote.call("agent_1", "cancel_current_research")
```
**Purpose**: Cancel current research  
**Status**: ❌ Not implemented

#### 9. `chart_view` - ⚠️ **MISSING**
```lua
remote.call("agent_1", "chart_view", true)
```
**Purpose**: Chart chunks within agent's view  
**Status**: ❌ Not implemented

## Summary

**Supported**: 4 actions  
**Available in Mod**: ~13 actions  
**Missing**: 9 actions (including critical ones like `craft_enqueue`)

## Priority for Adding

### High Priority
1. **`craft_enqueue`** - Essential for agents to craft items
2. **`set_entity_recipe`** - Essential for automation setup
3. **`get_inventory_item`** - Essential for item extraction

### Medium Priority
4. `set_entity_filter` - Useful for automation
5. `pickup_entity` - Useful for cleanup

### Low Priority
6. `set_inventory_limit` - Nice to have
7. `enqueue_research` - Nice to have
8. `cancel_current_research` - Nice to have
9. `chart_view` - Nice to have

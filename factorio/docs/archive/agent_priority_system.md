# Agent Priority System

## Priority Order

Agents follow this strict priority order:

### 1. DEFEND THE BASE (Highest Priority)
- **Detect enemies**: Look for biters, spitters, or other hostile entities
- **Attack enemies**: Engage enemies within reach
- **Repair structures**: Fix damaged player-built structures if possible
- **Protect base**: Prioritize defending player structures over other tasks

**Detection**:
- Check `get_reachable()` for entities with names containing "biter" or "spitter"
- Monitor agent state for damage indicators
- Check for damaged structures in reachable entities

**Actions**:
- Move toward enemies if not in range
- Attack enemies (may require weapon/ammo - check mod capabilities)
- Repair damaged structures

### 2. BUILD BLUEPRINTS (Medium Priority)
- **Detect ghosts**: Look for ghost entities (blueprints placed by players)
- **Build ghosts**: Place entities for ghost blueprints
- **Complete structures**: Finish incomplete blueprint structures
- **Follow blueprints**: Build according to player-placed blueprints

**Detection**:
- Check `get_reachable()` for entities with names containing "ghost" or "entity-ghost"
- Look for ghost entities in the game state

**Actions**:
- `place_entity` to build ghost entities
- Move to blueprint locations
- Build missing entities from blueprints

### 3. GATHER RESOURCES (Lowest Priority)
- **Mine resources**: Collect iron-ore, copper-ore, coal, stone
- **Craft items**: Create items from gathered resources
- **Only when idle**: Only gather resources when no defense or building tasks exist

**Detection**:
- Check `get_reachable()` for resources
- Check agent inventory for available materials

**Actions**:
- `mine_resource` to gather ores
- `craft_enqueue` to create items
- `walk_to` to move to resource locations

## Implementation

The LLM receives:
1. Priority instructions in the system prompt
2. Context about what's reachable (enemies, ghosts, resources)
3. Priority hints based on detected entities
4. Clear action examples

The agent will naturally prioritize based on the context provided, with the LLM making decisions according to the priority order.

## Future Enhancements

- **Explicit priority checking**: Add code to explicitly check for enemies/ghosts before querying LLM
- **State machine**: Implement a state machine that enforces priorities
- **Threat detection**: Better enemy detection and threat assessment
- **Blueprint tracking**: Track which blueprints need building
- **Resource management**: Smart resource gathering based on base needs

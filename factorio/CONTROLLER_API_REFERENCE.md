# Factorio Controller API Reference

## Endpoint

```
POST http://localhost:8080/execute-action
Content-Type: application/json
```

## Request Format

```json
{
  "agent_id": "1",
  "action": "action_name",
  "params": {
    // Action-specific parameters
  }
}
```

## Response Format

```json
{
  "success": true,
  "message": "Action executed successfully"
}
```

Or on error:
```json
{
  "success": false,
  "message": "Error message from Factorio"
}
```

## Supported Actions (13 total)

### 1. `walk_to` - Move to Position

**Parameters:**
- `x` (number): X coordinate
- `y` (number): Y coordinate

**Example:**
```json
{
  "agent_id": "1",
  "action": "walk_to",
  "params": {"x": 100, "y": 200}
}
```

---

### 2. `mine_resource` - Mine Resources

**Parameters:**
- `resource` or `resource_name` (string): Resource name (e.g., "iron-ore")
- `count` (number, optional): Amount to mine (omit to mine until depleted)

**Example:**
```json
{
  "agent_id": "1",
  "action": "mine_resource",
  "params": {"resource": "iron-ore", "count": 50}
}
```

---

### 3. `craft_enqueue` - Queue Crafting Recipe ⭐ NEW

**Parameters:**
- `recipe` or `recipe_name` (string): Recipe name (e.g., "iron-gear-wheel")
- `count` (number, optional): Amount to craft

**Example:**
```json
{
  "agent_id": "1",
  "action": "craft_enqueue",
  "params": {"recipe": "iron-gear-wheel", "count": 20}
}
```

---

### 4. `place_entity` - Place Building/Entity

**Parameters:**
- `entity` or `entity_name` (string): Entity name (e.g., "assembling-machine-1")
- `x` (number): X coordinate
- `y` (number): Y coordinate

**Example:**
```json
{
  "agent_id": "1",
  "action": "place_entity",
  "params": {"entity": "wooden-chest", "x": 10, "y": 10}
}
```

---

### 5. `set_entity_recipe` - Configure Machine Recipe ⭐ NEW

**Parameters:**
- `entity` or `entity_name` (string): Entity name (e.g., "assembling-machine-1")
- `x` (number): X coordinate
- `y` (number): Y coordinate
- `recipe` or `recipe_name` (string): Recipe name

**Example:**
```json
{
  "agent_id": "1",
  "action": "set_entity_recipe",
  "params": {
    "entity": "assembling-machine-1",
    "x": 105,
    "y": 205,
    "recipe": "iron-gear-wheel"
  }
}
```

---

### 6. `set_entity_filter` - Set Entity Filter ⭐ NEW

**Parameters:**
- `entity` or `entity_name` (string): Entity name (e.g., "fast-inserter")
- `x` (number): X coordinate
- `y` (number): Y coordinate
- `filter_type` (string, default: "inserter_stack_filter"): Filter type
- `filter_index` (number, default: 1): Filter slot index
- `item` (string): Item name to filter

**Example:**
```json
{
  "agent_id": "1",
  "action": "set_entity_filter",
  "params": {
    "entity": "fast-inserter",
    "x": 12,
    "y": 10,
    "filter_type": "inserter_stack_filter",
    "filter_index": 1,
    "item": "iron-plate"
  }
}
```

---

### 7. `set_inventory_limit` - Set Inventory Limit ⭐ NEW

**Parameters:**
- `entity` or `entity_name` (string): Entity name
- `x` (number): X coordinate
- `y` (number): Y coordinate
- `inventory` (string, default: "chest"): Inventory type
- `limit` (number, default: 10): Item limit

**Example:**
```json
{
  "agent_id": "1",
  "action": "set_inventory_limit",
  "params": {
    "entity": "chest",
    "x": 10,
    "y": 10,
    "inventory": "chest",
    "limit": 10
  }
}
```

---

### 8. `set_inventory_item` - Insert Items into Entity

**Parameters:**
- `entity` or `entity_name` (string, default: "wooden-chest"): Entity name
- `x` (number): X coordinate
- `y` (number): Y coordinate
- `inventory` (string, default: "chest"): Inventory type
- `item` (string): Item name
- `count` (number, optional): Amount to insert

**Example:**
```json
{
  "agent_id": "1",
  "action": "set_inventory_item",
  "params": {
    "entity": "assembling-machine-1",
    "x": 10,
    "y": 10,
    "inventory": "assembling_machine_input",
    "item": "iron-plate",
    "count": 100
  }
}
```

---

### 9. `get_inventory_item` - Extract Items from Entity ⭐ NEW

**Parameters:**
- `entity` or `entity_name` (string): Entity name
- `x` (number): X coordinate
- `y` (number): Y coordinate
- `inventory` (string, default: "chest"): Inventory type
- `item` (string): Item name
- `count` (number, optional): Amount to extract

**Example:**
```json
{
  "agent_id": "1",
  "action": "get_inventory_item",
  "params": {
    "entity": "assembling-machine-1",
    "x": 10,
    "y": 10,
    "inventory": "assembling_machine_output",
    "item": "iron-gear-wheel",
    "count": 50
  }
}
```

---

### 10. `pickup_entity` - Pick Up Entity from World ⭐ NEW

**Parameters:**
- `entity` or `entity_name` (string): Entity name
- `x` (number): X coordinate
- `y` (number): Y coordinate

**Example:**
```json
{
  "agent_id": "1",
  "action": "pickup_entity",
  "params": {"entity": "iron-ore", "x": 50, "y": 50}
}
```

---

### 11. `enqueue_research` - Queue Research ⭐ NEW

**Parameters:**
- `technology` or `tech_name` (string): Technology name (e.g., "automation")

**Example:**
```json
{
  "agent_id": "1",
  "action": "enqueue_research",
  "params": {"technology": "automation"}
}
```

---

### 12. `cancel_current_research` - Cancel Research ⭐ NEW

**Parameters:** None

**Example:**
```json
{
  "agent_id": "1",
  "action": "cancel_current_research",
  "params": {}
}
```

---

### 13. `chart_view` - Chart Chunks ⭐ NEW

**Parameters:**
- `rechart` (boolean, default: false): Rechart existing chunks

**Example:**
```json
{
  "agent_id": "1",
  "action": "chart_view",
  "params": {"rechart": true}
}
```

---

## Queue Actions (Phase 2)

Execute a chain of actions in order. Each step returns the same shape as single `POST /execute-action`. Keeps `POST /execute-action` for one-off calls.

```
POST http://localhost:8080/queue-actions
Content-Type: application/json
```

**Request:**
```json
{
  "agent_id": "1",
  "actions": [
    { "action": "walk_to", "params": {"x": 0, "y": 0} },
    { "action": "cancel_current_research", "params": {} }
  ]
}
```

**Response:**
```json
{
  "results": [
    { "step_index": 0, "action": "walk_to", "success": true, "message": "Action walk_to executed successfully" },
    { "step_index": 1, "action": "cancel_current_research", "success": true, "message": "Action cancel_current_research executed successfully" }
  ],
  "overall_success": true
}
```

- `results`: one entry per step, in order. Each has `step_index` (0-based), `action`, `success` (bool), `message` (str).
- `overall_success`: `true` only if every step returned `success: true`. Execution stops on first failure; remaining steps are not run.

---

## AI step (follow-me)

Run one **sense → LLM → act** cycle. The controller uses inspect, get-reachable, and player-position, injects **sensing ranges** (~2.7 tiles resources, ~10 tiles entities) and follow-me instructions into the LLM context, then executes the chosen action.

```
POST http://localhost:8080/ai-step
Content-Type: application/json
```

**Request:**
```json
{
  "agent_id": "1",
  "mode": "follow",
  "last_result": "walk_to executed"
}
```

- `agent_id`: Which agent to run (default `"1"`).
- `mode`: `"follow"` — follow the player to resource patches; more modes may be added.
- `last_result`: Optional. Message from the previous step so the LLM can chain decisions.

**Response:**
```json
{
  "action": "walk_to",
  "params": {"x": 100, "y": 200},
  "result": {"success": true, "message": "Action executed"},
  "player_position": {"x": 95.2, "y": 198.1}
}
```

To run the AI in a loop from your machine, use `agent_scripts/run_ai_follow.py`:

```bash
CONTROLLER_URL=http://192.168.0.158:8080 python run_ai_follow.py
```

The controller must be able to reach Ollama (set `OLLAMA_HOST` when the controller runs on NAS and Ollama is elsewhere).

---

## Health Check

```
GET http://localhost:8080/health
```

**Response:**
```json
{
  "status": "healthy",
  "rcon": "connected",
  "service": "factorio-http-controller"
}
```

## Get Reachable Entities

```
GET http://localhost:8080/get-reachable?agent_id=1
```

**Response:**
```json
{
  "entities": [...],
  "resources": [...]
}
```

Optional keys (when the FV mod includes them): `ghosts`, `enemies`, `agent_position`, `tick`.

### Sensing: range and what the agent sees

**How far** the agent “sees” is determined by the Factorio character’s reach (FV Embodied Agent uses the same logic):

| What | Distance (default) | Used for |
|------|--------------------|----------|
| **Resources** (ore, trees, rocks) | **~2.7 tiles** | `character.reach_resource_distance` — mining / harvesting |
| **Other entities** (machines, chests, ghosts, etc.) | **~10 tiles** | `character.reach_distance` — build, loot, configure, pickup |

Distances are from the character’s center. Exact values can be changed by mods or character prototype overrides; the table above reflects Factorio’s base defaults.

**What each sense returns:**

| Sense | Returns |
|-------|--------|
| **inspect** | Agent id, `position` {x,y}, `force`, and optional `state` (e.g. `walking`, `mining`, `crafting` with goal/recipe/queue). Use for “where am I and what am I doing?” |
| **get-reachable** | `entities`: machines, inserters, chests, etc., with name, position, optional recipe/inventory. `resources`: ore, wood, etc., with name, position, amount. Optional: `ghosts` (blueprint ghosts), `enemies`, `agent_position`, `tick`. |
| **get-recipes** / **get-technologies** | Lists of names (and for tech, researched vs all). Reference data; not tied to reach. |

So the agent “sees” only what is within **~2.7 tiles** (resources) or **~10 tiles** (entities). Anything beyond that is unknown until the agent moves or uses **chart_view** to reveal chunks on the map (no per-entity data, only charting).

## Inspect (agent state)

```
GET http://localhost:8080/inspect?agent_id=1
```

**Response:** Agent state (position, activity). Example shape: `{ "agent_id", "position": { "x", "y" }, "force", "state": { "walking", "mining", "crafting" } }`. Raw FV output.

## Player position

```
GET http://localhost:8080/player-position
```

**Response:** `{ "x": <float>, "y": <float> }` for the first connected player’s character, or `{}` if none. Used by follow-me AI to walk the agent toward the player.

## Players (tracked)

```
GET http://localhost:8080/players
```

**Response:** `[{ "name": "<player name>", "position": { "x", "y" } }, ...]` for all connected players with characters. Refreshed on each call and stored as player context for every LLM prompt. The controller **always** refreshes this before any LLM call and injects it into the prompt, along with:

- **Rule:** Do not come closer than **5 tiles** (configurable via env `FOLLOW_MIN_TILES`) to any player.
- **Suggested follow target:** A point 5 tiles from the nearest player toward the agent; the LLM is told to use this for `walk_to`, not the player's exact position.

So the agent follows the player but stays at least 5 tiles away. Extra senses can be added later and injected the same way.

## Get Recipes

```
GET http://localhost:8080/get-recipes?agent_id=1
```

**Response:** Available recipes for the agent's force. Example: `{ "recipes": ["iron-gear-wheel", ...] }`.

## Get Technologies

```
GET http://localhost:8080/get-technologies?agent_id=1
GET http://localhost:8080/get-technologies?agent_id=1&researched_only=true
```

**Response:** Technologies. `researched_only=true` returns only researched techs.

**Implementation note (RCON output):** Sense endpoints (inspect, get-reachable, get-recipes, get-technologies) use Lua `rcon.print(helpers.table_to_json(...))` so the RCON client receives the payload. Factorio’s `/sc return ...` does not send Lua return values to RCON; only `rcon.print()` output is returned. Requires Factorio 2.0 (or a build where the global `helpers` and `helpers.table_to_json` exist).

---

## Reference data (recipes / technologies)

Recipes and technologies are **reference data**: they list all recipes/techs from the base game and loaded mods. They change only when the game or mod set changes.

### Auto-refresh on RCON connect

The controller refreshes its reference cache **whenever it connects to RCON** (at startup or on the first request that uses RCON). Any LLM or client that hits the API triggers a refresh, so mod changes are picked up without a manual pull.

- **Trigger:** First successful RCON connect (startup or lazy connect on first sense/action).
- **Debounce:** At most once every 5 minutes (`REFERENCE_REFRESH_DEBOUNCE_SEC`, default 300).
- **Config:** `REFERENCE_DATA_DIR` (default `.reference_data`), `REFERENCE_AGENT_ID` (default `1`), `REFERENCE_DATA_DISABLED=1` to turn off.

### Cached reference endpoints (read-only)

After a refresh, the controller serves cached JSON from disk so clients can avoid RCON calls:

```
GET http://localhost:8080/reference/recipes
GET http://localhost:8080/reference/technologies
GET http://localhost:8080/reference/technologies_researched
```

**Response:** JSON body of the cached file (recipes, all technologies, or researched-only technologies). No query params. Returns 404 if the cache has not been written yet (e.g. no RCON connect yet).

### How the LLM accesses reference data

After the controller has refreshed its cache (on RCON connect), the LLM can get recipes/technologies in these ways:

1. **Controller-internal (automatic)**  
   When the controller builds the LLM context (e.g. in `query_llm_for_workflow`), it reads the cache from disk and appends a short snippet to the prompt: “Available recipes (cached)” and “Researched technologies (cached)” as comma-separated names (truncated to avoid huge prompts). So any LLM call that goes through the controller’s NPC/LLM loop already receives this without extra wiring.

2. **HTTP from n8n or other clients**  
   Before or when calling the LLM, the client can `GET /reference/recipes`, `GET /reference/technologies`, and/or `GET /reference/technologies_researched`, then put that JSON (or a summary) into the system/user prompt or into a “context” field the LLM sees.

3. **Tools / function-calling**  
   If the LLM has tools (e.g. `get_recipes`, `get_technologies`), the runtime can implement them by requesting the controller’s base URL plus `/reference/recipes` or `/reference/technologies_researched` and returning the response body. The LLM then calls those tools when it needs recipe/tech info.

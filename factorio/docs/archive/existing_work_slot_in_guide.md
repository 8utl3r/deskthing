# Existing Work Slot-In Guide

**Purpose:** Identify pieces we can reuse instead of building everything from scratch.  
**Current stack:** n8n → Python HTTP controller (:8080) → RCON → Factorio + FV Embodied Agent.

**Related:** [feature_charts_by_component.md](feature_charts_by_component.md) — feature charts for mods, HTTP→RCON, RCON client, and circuit components; use it to compare options per part of the stack.

---

## 1. HTTP → RCON layer (replace or complement our controller)

### factorio-rcon-api (nekomeowww)

| Aspect | Details |
|--------|---------|
| **What** | Go service: REST + gRPC in front of Factorio RCON. |
| **Image** | `ghcr.io/nekomeowww/factorio-rcon-api`, port 24180. |
| **Raw Lua** | `POST /api/v2/factorio/console/command/raw` with `{"input": "/sc ..."}` runs arbitrary Lua. |
| **Docs** | [Live API docs](https://factorio-rcon-api.ayaka.io/apis/docs/v2), OpenAPI spec in repo. |

**Slot-in:** Use their image as the HTTP→RCON layer. Our controller’s jobs today: (a) HTTP server, (b) map `{agent_id, action, params}` → Lua string, (c) RCON. Factorio-rcon-api covers (a)+(c). We keep a thin adapter that turns our JSON into the Lua string and calls their raw endpoint.

**Where the adapter can live:**  
- **n8n:** Code node + HTTP Request: build `/sc remote.call('agent_N', ...)` and POST to their raw URL.  
- **Or** a tiny sidecar (e.g. 50-line script or minimal n8n sub-workflow) that exposes our existing `/execute-action` shape and forwards to factorio-rcon-api.

**Effort:** Low. One-time mapping of our 13 actions to Lua strings; no RCON client or connection logic to maintain.  
**Recommendation:** Strong candidate if you want to drop the custom Python RCON/HTTP server and depend on an off-the-shelf HTTP→RCON service.

---

### factorio-api-go (cfindlayisme)

| Aspect | Details |
|--------|---------|
| **What** | REST API for Factorio servers (Go). |
| **Where** | [pkg.go.dev/github.com/cfindlayisme/factorio-api-go](https://pkg.go.dev/github.com/cfindlayisme/factorio-api-go). |

**Slot-in:** Likely overlaps with factorio-rcon-api (REST in front of Factorio). We didn’t inspect whether it exposes a “raw command” style endpoint. If it does, it could be an alternative to factorio-rcon-api; otherwise it’s mostly relevant for structured admin/version endpoints.

**Effort:** Unknown until we check for a raw Lua/console endpoint.  
**Recommendation:** Only revisit if factorio-rcon-api doesn’t fit (licensing, deployment, etc.).

---

### factorio-rcon-py (mark9064)

| Aspect | Details |
|--------|---------|
| **What** | Python RCON client for Factorio. |
| **Use** | We already use it inside our controller. |

**Slot-in:** Library, not a service. No “slot-in” replacement for the controller; it’s the implementation detail we’d keep or drop when we switch to something like factorio-rcon-api.  
**Recommendation:** Keep using it as long as we keep the Python controller; if we move to factorio-rcon-api, we no longer need it in our stack.

---

## 2. Game-side mod (alternative to FV Embodied Agent)

### factorio-automation (naklecha)

| Aspect | Details |
|--------|---------|
| **What** | Mod exposing `remote.call("factorio_tasks", "command_name", ...)`. |
| **Commands** | `walk_to_entity`, `mine_entity`, `place_entity`, `place_item_in_chest`, `auto_insert_nearby`, `pick_up_item`, `craft_item`, `research_technology`, `attack_nearest_enemy`, `log_player_info`. |
| **Repo** | [github.com/naklecha/factorio-automation](https://github.com/naklecha/factorio-automation) (≈111 stars, WIP). |

**Slot-in:** Could replace FV Embodied Agent as the mod that handles movement/crafting/inventory. Differences: (1) interface is `"factorio_tasks"` with different call shapes (e.g. `walk_to_entity(entity_type, entity_name, search_radius)` vs our `walk_to({x,y})`); (2) no explicit multi-agent ID in the same way—oriented around “player”/task; (3) adds research + combat; (4) no machine-config primitives like `set_entity_recipe` / `set_entity_filter`.

**Effort:** Medium–high: new mod in the game, rewrite our action→Lua mapping, and either give up multi-agent or design an extra mapping layer.  
**Recommendation:** Use only if we deliberately switch off FV (e.g. for research/combat). Our feature matrix already recommends FV for LLM/multi-agent; no need to swap unless we want that different feature set.

---

## 3. Other niches (additive, not replacement)

### factorio-constant-combinator-rest-api (DirkHeinke)

| Aspect | Details |
|--------|---------|
| **What** | REST API to read/write constant combinators and circuit network signals. |
| **Endpoints** | `GET/POST/DELETE /cc/:id/signal/:slot` with body like `{signalName, signalType, signalCount}`. |
| **Repo** | [github.com/DirkHeinke/factorio-constant-combinator-rest-api](https://github.com/DirkHeinke/factorio-constant-combinator-rest-api). |

**Slot-in:** Doesn’t replace the agent controller. Use when we want “n8n ↔ circuit network” (e.g. set combinator signals from workflows).  
**Recommendation:** Slot in later if we add circuit-based automation; no change to current agent stack.

---

### Factorio Learning Environment (FLE)

**What:** Eval framework (Python, RCON, Lua bridge, REPL-style).  
**Slot-in:** Aimed at benchmarks/evals, not at being a drop-in for our n8n + FV agent setup.  
**Recommendation:** Skip for “replace our controller/mod” purposes; optional read if we do benchmark/evals later.

---

### lvshrd/factorio-agent, Factorio-LLM-Testing, etc.

- **factorio-agent:** OpenAI Agent SDK + RCON + “Factorio Runtime API”; different stack (OpenAI, not Ollama/n8n). Reuse would mean borrowing RCON/tool patterns and wiring them to our stack—no direct binary/service to slot in.  
- **Factorio-LLM-Testing:** Good reference for “LLM → RCON → Factorio”; we already mirror that pattern with n8n + controller + FV.

---

## Summary: what to slot in today

| Goal | Piece | Action |
|------|--------|--------|
| Less custom code, off-the-shelf HTTP→RCON | **factorio-rcon-api** | Run their image; add thin adapter in n8n or tiny sidecar that maps our `{agent_id, action, params}` → `POST .../raw` with `/sc remote.call(...)`. |
| Keep current Python controller | — | No change; we keep factorio-rcon-py and our HTTP server. |
| Different mod (research/combat, single “task” style) | **factorio-automation** | Swap FV for this mod and reimplement action→Lua for their interface. |
| Circuit control from n8n | **factorio-constant-combinator-rest-api** | Add later alongside current stack. |

**Practical next step:** If you want to depend on external HTTP→RCON and shrink our codebase, implement the thin “JSON → factorio-rcon-api raw” adapter (in n8n or a minimal sidecar) and point n8n at it instead of the current Python controller; then we can retire the controller’s RCON/HTTP bits and keep only that mapping.

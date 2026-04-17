# Feature Charts by Component

**Purpose:** Compare options for each part of the stack so you can pick the right mod and the right HTTP/RCON pieces.  
**Stack:** `n8n → [HTTP/RCON layer] → [RCON] → Factorio + [Mod]`.

---

## Stack overview

| Part | What it does | You choose |
|------|----------------|------------|
| **1. Mod** | In-game agents, remote interface, actions | FV Embodied Agent vs factorio-automation vs others |
| **2. HTTP → RCON** | Exposes Factorio to HTTP (so n8n can call it) | Our controller vs factorio-rcon-api vs n8n-only |
| **3. RCON client** | Talks TCP to Factorio (only if you run your own HTTP layer) | factorio-rcon-py vs factorio-rcon (Go) |
| **4. Circuit/other** | Optional: control combinators, evals, etc. | constant-combinator-rest-api, FLE |

---

## Part 1: Game mod (detailed — “did I pick the wrong one?”)

Components that run *inside Factorio* and expose a remote interface (called via `/sc remote.call(...)` over RCON).

| Feature | FV Embodied Agent | factorio-automation | factorio-ai-bot | factorio-bot | Ember Autopilot | kk-remote | Custom mod |
|--------|-------------------|---------------------|-----------------|-------------|-----------------|----------|------------|
| **Type** | Mod (Lua) | Mod (Lua) | External (C++) | External (Rust/Tauri) | Framework (Lua) | Mod (Lua) | Mod (Lua) |
| **Interface** | `agent`, `agent_<id>` | `factorio_tasks` | Log file / GUI | — | ❓ | Remote API fork | ⚙️ You define |
| **Multi-agent** | ✅ Yes (agent_1, agent_2…) | ❌ Player/task style | ❌ Single bot | ❓ | ❓ | ❓ | ⚙️ |
| **Movement** | ✅ `walk_to({x,y})` pathfinding | ✅ `walk_to_entity(type,name,radius)` | ✅ WASD sim | ❓ | ❓ | ❓ | ⚙️ |
| **Mining** | ✅ `mine_resource(name,count)` async | ✅ `mine_entity(type,name)` | ✅ Auto 5-tile | ❓ | ❓ | ❓ | ⚙️ |
| **Crafting** | ✅ `craft_enqueue(recipe,count)` | ✅ `craft_item(name,count)` | ❌ | ❓ | ❓ | ❓ | ⚙️ |
| **Building** | ✅ `place_entity(name,{x,y})` | ✅ `place_entity(name)` | ❌ | ❓ | ❓ | ❓ | ⚙️ |
| **Machine config** | ✅ `set_entity_recipe`, `set_entity_filter`, `set_inventory_limit` | ❌ | ❌ | ❌ | ❓ | ❓ | ⚙️ |
| **Research** | ❌ | ✅ `research_technology(name)` | ❌ | ❓ | ❓ | ❓ | ⚙️ |
| **Combat** | ❌ | ✅ `attack_nearest_enemy(radius)` | ❌ | ❓ | ❓ | ❓ | ⚙️ |
| **Inventory** | ✅ `set_*`, `get_inventory_item`, `pickup_entity` | ✅ `place_item_in_chest`, `pick_up_item`, `auto_insert_nearby` | ❌ | ❓ | ❓ | ❓ | ⚙️ |
| **State/observe** | ✅ `inspect`, `get_reachable` | ✅ `log_player_info` | ✅ Log file | ❓ | ❓ | ❓ | ⚙️ |
| **Headless** | ✅ | ✅ | ❌ Needs GUI | ❓ | ❓ | ❓ | ⚙️ |
| **Async actions** | ✅ UDP completion | ❓ | ❌ | ❓ | ❓ | ❓ | ⚙️ |
| **Pathfinding** | ✅ Built-in | ❓ | ❌ | ❓ | ❓ | ❓ | ⚙️ |
| **Docs / maintenance** | Mod portal, v0.1.3, Factorio 2.0 | GitHub, WIP, ~111★ | GitHub | GitHub | Limited | Fork, remote API | ⚙️ |
| **Link** | [mods.factorio.com/mod/fv_embodied_agent](https://mods.factorio.com/mod/fv_embodied_agent) | [github.com/naklecha/factorio-automation](https://github.com/naklecha/factorio-automation) | GitHub | GitHub | — | [Factorio-Access/kk-remote](https://github.com/Factorio-Access/kk-remote) | — |

**Legend:** ✅ Supported | ❌ No | ❓ Unknown | ⚙️ You can build it.

### Mod picker by use case

| Your goal | Best mod | Why |
|-----------|----------|-----|
| **Multiple LLM-controlled NPCs (n8n/Ollama)** | **FV Embodied Agent** | Multi-agent IDs, async, `inspect`/`get_reachable`, machine config, headless. |
| **Single “task” runner + research/combat** | **factorio-automation** | Research + combat; no machine config; player/task style, not multi-agent. |
| **Computer vision / screen-based bot** | **factorio-ai-bot** | OpenCV, GUI required; not headless. |
| **Desktop automation / one bot** | **factorio-bot** | External app; check if headless and API exist. |
| **Max control, own interface** | **Custom mod** | Build exactly the remote API you need. |

**Summary:** For “n8n + multiple agents + machine config + headless,” FV is the right pick. Use factorio-automation only if you want research/combat and can give up multi-agent and machine-config.

---

## Part 2: HTTP → RCON layer

Components that give n8n (or another app) an HTTP way to run Lua on Factorio.

| Feature | Our Python controller | factorio-rcon-api | factorio-api-go | n8n only (Code + HTTP) |
|--------|------------------------|-------------------|------------------|--------------------------|
| **What** | HTTP :8080, maps JSON→Lua, holds RCON | REST+gRPC in front of RCON | REST for Factorio | RCON from Code node |
| **Raw Lua** | Yes (we build `/sc ...`) | ✅ `POST .../command/raw` | ❓ | Yes (you build strings) |
| **Our action API** | ✅ `/execute-action` + 13 actions | No — need thin adapter | ❓ | You implement in workflow |
| **Image/deploy** | Our image or volume on NAS | `ghcr.io/nekomeowww/factorio-rcon-api` :24180 | ❓ | None (logic in n8n) |
| **Depends on** | factorio-rcon-py, Python | Go binary | Go | RCON client in Code (e.g. Python) |
| **Best for** | Full control, one service | Less code, off-the-shelf HTTP→RCON | Unknown until API checked | Minimal services, willing to put logic in n8n |

---

## Part 3: RCON client (only if you run your own HTTP layer)

| Component | Language | Use |
|-----------|-----------|-----|
| **factorio-rcon-py** | Python | We use this in our controller. |
| **factorio-rcon** (gtaylor) | Go | If you write the HTTP layer in Go. |

If you use factorio-rcon-api as the HTTP layer, you don’t need an RCON client in your stack.

---

## Part 4: Circuit / other (additive)

| Component | Purpose | Replaces mod/controller? |
|-----------|---------|---------------------------|
| **factorio-constant-combinator-rest-api** | Control constant combinators via REST | No — add for circuit automation. |
| **Factorio Learning Environment (FLE)** | Benchmarks / evals, REPL-style | No — use for evals only. |

---

## Quick ref: “Did I pick the wrong mod?”

- **You want:** multiple agents, headless, n8n/Ollama, set recipes/filters on machines → **FV Embodied Agent** ✅  
- **You want:** research + combat, single “task” style, no machine config → **factorio-automation**  
- **You want:** vision/screen bot → **factorio-ai-bot** (not headless)  
- **You want:** zero in-game mod, external bot only → **factorio-bot** or similar (confirm headless/API).

See [factorio_ai_automation_feature_matrix.md](factorio_ai_automation_feature_matrix.md) for full use-case notes and [existing_work_slot_in_guide.md](existing_work_slot_in_guide.md) for slot-in details.

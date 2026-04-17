# Factorio agent scripts (Python)

Python scripts that drive FV Embodied Agent via the **controller HTTP API**.  
Controller stays on the NAS; you develop and test scripts on your Mac, then deploy them to the NAS when ready.

---

## Workflow

1. **Develop on Mac** – Edit scripts in `factorio/agent_scripts/`.
2. **Test on Mac** – Point at the NAS controller:  
   `CONTROLLER_URL=http://192.168.0.158:8080 python example_walk.py`
3. **Verify** – Use `./verify_connections.sh` from `factorio/` (with `CONTROLLER_URL` and `RCON_PASSWORD`) to confirm controller and RCON.
4. **Deploy to NAS** – Copy `agent_scripts/` to the NAS (e.g. next to the controller or into a dedicated dir) and run with `CONTROLLER_URL=http://localhost:8080`.

---

## Setup (Mac)

**From your dotfiles root** (e.g. `/Users/pete/dotfiles`):

```bash
cd factorio/agent_scripts
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

If you're already in `factorio/`, use `cd agent_scripts` (no extra `factorio/`).

---

## Config

- **CONTROLLER_URL** – Controller base URL.  
  - Mac → NAS: `http://192.168.0.158:8080`  
  - On NAS: `http://localhost:8080`
- **Default** if unset: `http://127.0.0.1:8080`

---

## Scripts

| Script | Purpose |
|--------|---------|
| `controller_client.py` | Thin client: `health()`, `get_reachable(agent_id)`, `execute_action(...)`, `queue_actions(agent_id, actions)`. Import in your scripts. |
| `example_walk.py` | Example: health check, then `walk_to(0, 0)` for agent 1. Run to confirm the stack works. |
| `verify_actions.py` | Phase 1: canonical request per action, checks `{success, message}`. See run commands below. |
| `verify_queue.py` | Phase 2: smoke test for `POST /queue-actions` (chain walk_to + cancel_current_research). Same run pattern as verify_actions. |
| `verify_actions_ingame.py` | In-game verification: every action must return success=True. If get_reachable is empty, agent walks ever-larger squares (default max_radius=480, wait_sec=12; 4× longer). Env: EXPLORE_WALK_WAIT_SEC, EXPLORE_MAX_RADIUS, EXPLORE_STEP, EXPLORE_VERBOSE. |
| `test_walk_to.py` | **Per-action test**: walk_to only. Health, then walk_to(0,0), assert success. Run first when mastering FV actions one at a time. |
| `sense_raw.py` | **Live sense summary**: inspect + get_reachable only (one line each). Set `INCLUDE_REFERENCE=1` to add recipes/technologies. |
| `sense_inspect.py` | GET /inspect only — agent state (position, activity). |
| `sense_reachable.py` | GET /get-reachable only — entities and resources in range. |
| `sense_recipes.py` | GET /get-recipes only — *all* recipes (game + mods). Use for one-off dumps; prefer cached data (see below). |
| `sense_technologies.py` | GET /get-technologies only — *all* techs (game + mods). Use for one-off dumps; prefer cached data. `RESEARCHED_ONLY=true` for researched only. |
| `refresh_reference_data.py` | Fetch recipes + technologies from controller and write to `reference_data/*.json`. **Run after game or mod changes.** Other code reads from those files. |
| `run_ai_follow.py` | **AI follow-me loop**: calls `POST /ai-step` so the agent follows the player. Respects sequence state (only runs when "follow" is enabled and highest priority). Env: `CONTROLLER_URL`, `AGENT_ID`, `AI_STEP_INTERVAL`. |
| `sense_loop.py` | **Base**: background process. Polls controller ~0.25s, writes `world_state.json`. No UI — run in background or a separate terminal. Other sequences depend on this. Env: `CONTROLLER_URL`, `AGENT_ID`, `SENSE_POLL_INTERVAL`, `WORLD_STATE_PATH`. |
| `dashboard.py` | **Dashboard**: display-only UI. Reads `world_state.json` and `sequence_state.json`; does not talk to the controller. Shows base (sense loop) status, stats, entities/players, and Sequences. Env: `WORLD_STATE_PATH`, `DASHBOARD_REFRESH`. |
| `sequence_state.py` | Shared sequence state (definitions, load/save, priority). Used by dashboard, agent_control, and sequence runners. State file: `sequence_state.json` (or `SEQUENCE_STATE_PATH`). |
| `module_control.py` | **API layer** for module (sequence) control. Used by agent_control CLI and by MCP/LLM API. Functions: `list_modules()`, `enable_module(id)`, `disable_module(id)`, `set_module_priority(id, n)`, `set_module_var(id, key, value)`. All return structured dicts. |
| `fa` | **CLI entry point** (executable). Run `fa <command> [args]` — e.g. `fa list`, `fa enable follow`, `fa ?` for help. Add `agent_scripts` to PATH to use from anywhere. `factorio-agent` is a symlink to `fa`. |
| `agent_control.py` | Implementation of fa CLI. Use `--json` for machine output (MCP, API, LLM). Commands: `list`, `status`, `enable`, `disable`, `set-priority`, `set-var`, `help`, `?`. |

---

## Dashboard + sense loop + control

**Base (run in background):** sense loop polls the controller and writes `world_state.json`. This is the base layer; the dashboard and sequences depend on it.

```bash
cd factorio/agent_scripts && CONTROLLER_URL=http://192.168.0.158:8080 python sense_loop.py
```

**Dashboard (display only):** reads `world_state.json` and `sequence_state.json`. No CONTROLLER_URL needed. Shows base status (sense loop → file, last updated), stats, entities/players, and Sequences panel.

```bash
cd factorio/agent_scripts && python dashboard.py
```

**Control (CLI):** use the `fa` command (like SSH: one command, structured subcommands). Run `fa` with no args to enter an interactive shell (`fa>` prompt); type commands there and `exit` or `quit` to leave. Use `--json` for API/MCP/LLM.

```bash
cd factorio/agent_scripts
./fa
```

At the `fa>` prompt: `list`, `enable follow`, `set-var mine_all resource iron-ore`, `check`, `help`, `exit`. Or run one-shot: `./fa list`, `./fa enable follow`, `./fa check`.

**`fa check`** — When follow is on but the agent is not following, run `fa check` (or `CONTROLLER_URL=... fa check`). It prints sequence state, pings the controller if CONTROLLER_URL is set, and reminds you to run `run_ai_follow.py` in another terminal. The agent only moves when that script is running; enabling "follow" in fa only allows it to act.

Add `agent_scripts` to PATH (or symlink `fa` to `~/bin`) to run from anywhere. The CLI calls `module_control.py`; the same API layer is the basis for the MCP connection to the LLM.

**Sequence runner (required for follow):** For the agent to actually follow, you must run the runner script in a separate terminal. Only the **highest-priority enabled** sequence runs; the runner reads `sequence_state.json` each tick.

```bash
cd factorio/agent_scripts && CONTROLLER_URL=http://192.168.0.158:8080 python run_ai_follow.py
```

Summary: **sense_loop** = base, background writer. **dashboard** = display only, reads files. **agent_control** = toggle sequences/vars. **run_ai_follow** (etc.) = sequence runners. Sequences have priorities (lower = runs first) and variables (e.g. mine_all `resource`).

---

## Run AI follow-me

The agent uses sensing and player position to decide one action per step (walk toward player, mine resource, or no-op). **Two things must be true:** (1) `fa enable follow` so the follow module is on and has highest priority; (2) **this script must be running** in a terminal. Enabling follow in fa only allows the runner to act; the runner must be running for the agent to move.

```bash
cd factorio/agent_scripts && CONTROLLER_URL=http://192.168.0.158:8080 python run_ai_follow.py
```

Optional: `AGENT_ID=1` (default), `AI_STEP_INTERVAL=0.25`. The controller must reach Ollama; if the controller is on NAS and Ollama is on your Mac, set `OLLAMA_HOST` when starting the controller.

---

## Run verify_actions.py (Phase 1 check)

The script **must be run from inside `agent_scripts/`** (it imports `controller_client` from the same dir).

**From dotfiles root** (e.g. `/Users/pete/dotfiles`):

```bash
cd factorio/agent_scripts && CONTROLLER_URL=http://192.168.0.158:8080 python verify_actions.py
```

**From `factorio/`** (one level above `agent_scripts`):

```bash
cd agent_scripts && CONTROLLER_URL=http://192.168.0.158:8080 python verify_actions.py
```

If you omit `CONTROLLER_URL`, it uses `http://127.0.0.1:8080` (fails if the controller isn’t local).

**Queue smoke test (Phase 2):**
```bash
cd factorio/agent_scripts && CONTROLLER_URL=http://192.168.0.158:8080 python verify_queue.py
```

---

## Run sense scripts (one sense per file)

**Live summary** (inspect + get_reachable only; no recipes/technologies):
```bash
cd factorio/agent_scripts && CONTROLLER_URL=http://192.168.0.158:8080 python sense_raw.py
```
Optional: `INCLUDE_REFERENCE=1` to also summarize recipes and technologies.

**Full output for a single sense** (run from `agent_scripts/`):
```bash
CONTROLLER_URL=http://192.168.0.158:8080 python sense_inspect.py
CONTROLLER_URL=http://192.168.0.158:8080 python sense_reachable.py
CONTROLLER_URL=http://192.168.0.158:8080 python sense_recipes.py
CONTROLLER_URL=http://192.168.0.158:8080 python sense_technologies.py
CONTROLLER_URL=http://192.168.0.158:8080 RESEARCHED_ONLY=true python sense_technologies.py
```
Optional: `AGENT_ID=2` to query a different agent.

### Reference data (recipes / technologies)

Recipes and technologies are **reference data**: they list *all* recipes/techs from the base game and loaded mods. They do not change during a run, only when the game or mod set changes.

**Automated refresh:** The controller refreshes its reference cache **whenever it connects to RCON** (e.g. when an LLM or client first hits the API). So you don’t need to remember to run a pull—any use of the controller after a mod change will trigger a refresh. See `factorio/CONTROLLER_API_REFERENCE.md` (Reference data) for env vars and debounce.

**How to use them:**

1. **From the controller cache** — After the controller has connected to RCON, use the cached endpoints (no Factorio call):
   ```bash
   curl -s "http://192.168.0.158:8080/reference/recipes"
   curl -s "http://192.168.0.158:8080/reference/technologies"
   curl -s "http://192.168.0.158:8080/reference/technologies_researched"
   ```
   Returns 404 if the cache hasn’t been written yet.

2. **Local copy (optional)** — To keep a local `reference_data/` dir in sync, run when you want files on disk:
   ```bash
   CONTROLLER_URL=http://192.168.0.158:8080 python refresh_reference_data.py
   ```
   Or pull from the controller’s cache (faster, no RCON):
   ```bash
   curl -s "http://192.168.0.158:8080/reference/recipes" > reference_data/recipes.json
   ```

3. **Live senses** — Use **inspect** and **get_reachable** for current world state in loops; do not call recipes/technologies on every tick.

---

## Run (Mac, controller on NAS)

**From dotfiles root:**

```bash
cd factorio/agent_scripts
source .venv/bin/activate
CONTROLLER_URL=http://192.168.0.158:8080 python example_walk.py
```

**Or from `factorio/`:** `cd agent_scripts` then `source .venv/bin/activate` and the same `CONTROLLER_URL=http://192.168.0.158:8080 python example_walk.py`.

---

## Deploy to NAS

1. **Copy** `agent_scripts/` to the NAS, e.g.:
   ```bash
   scp -r factorio/agent_scripts truenas_admin@192.168.0.158:/mnt/boot-pool/apps/factorio-controller/
   ```
   or rsync from your dotfiles repo.

2. **On NAS** – Install deps and run with local controller URL:
   ```bash
   cd /mnt/boot-pool/apps/factorio-controller/agent_scripts
   python3 -m venv .venv && source .venv/bin/activate
   pip install -r requirements.txt
   CONTROLLER_URL=http://localhost:8080 python example_walk.py
   ```

3. **Scheduling** – Use cron or a systemd timer on the NAS to run the scripts you need (e.g. `example_walk.py` or your own).

---

## Controller API (used by scripts)

- `GET /health` – Controller and RCON status.
- `GET /get-reachable?agent_id=1` – Entities/resources in range for that agent.
- `GET /reference/recipes`, `GET /reference/technologies`, `GET /reference/technologies_researched` – Cached reference data (no RCON). Updated automatically when the controller connects to RCON.
- `POST /execute-action` – Body: `{"agent_id":"1","action":"walk_to","params":{"x":0,"y":0}}`.  
- `POST /queue-actions` – Body: `{"agent_id":"1","actions":[{"action":"walk_to","params":{"x":0,"y":0}},...]}`. Returns `{results, overall_success}`.  
  See `factorio/CONTROLLER_API_REFERENCE.md` for all actions and queue format.

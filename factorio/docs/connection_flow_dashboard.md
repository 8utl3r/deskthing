# Connection flow: game → dashboard (player position)

This doc traces every link from Factorio game to the dashboard so you can find why "position doesn't update."  
Commands use the controller URL **http://192.168.0.158:8080** (static lease).

## End-to-end path

```
Factorio game (player.character.position)
    ↓ RCON (Lua: game.connected_players, rcon.print)
Controller (factorio_http_controller.py)
    GET /players → get_players() → refresh_player_context()
    ↓ HTTP JSON [{name, position: {x,y}}, ...]
controller_client.players()
    ↓
sense_loop.py sense_once()
    inspect(agent_id), get_reachable(agent_id), players()
    ↓ writes JSON
world_state.json (agent_scripts/world_state.json by default)
    ↓ read by
dashboard.py _load_world_state()
    state["players"] → Players panel (name, position)
```

## Link-by-link

### 1. Game → RCON

- **Controller** sends Lua over RCON: `get_players()` builds lines `x,y,name` per player and calls `rcon.print(table.concat(lines, '\n'))`.
- Factorio provides global `rcon` in `/sc` when connected via RCON; output goes back to the RCON client.
- **If this fails:** Controller gets empty response → `get_players()` returns `[]`. Check: RCON connected (controller health shows rcon ok), game has at least one connected player with a character.

### 2. Controller HTTP GET /players

- **factorio_http_controller.py** path `/players`: calls `self.controller.refresh_player_context()` → `get_players()`.
- Response: JSON array `[{ "name": "...", "position": { "x": float, "y": float } }, ...]`.
- **If this fails:** Sense loop gets empty list or request error. Check: `curl -s http://192.168.0.158:8080/players` returns non-empty array when a player is in game.

### 3. controller_client.players()

- **controller_client.py** `players()`: `GET {CONTROLLER_URL}/players`, returns `r.json()`.
- Uses `CONTROLLER_URL` from environment (or default 127.0.0.1:8080).
- **If this fails:** Timeout, connection refused, or JSON error. Check: controller reachable from host running sense_loop (e.g. `curl -s http://192.168.0.158:8080/health`).

### 4. sense_loop.py

- **sense_loop.py** `sense_once()` calls `inspect(AGENT_ID)`, `get_reachable(AGENT_ID)`, `players()`.
- Builds `state = { timestamp, agent_id, agent, players, reachable }`, writes to `OUTPUT_PATH`.
- **OUTPUT_PATH** = `os.environ.get("WORLD_STATE_PATH", os.path.join(dirname(sense_loop.py), "world_state.json"))` → default `agent_scripts/world_state.json`.
- **If this fails:** Sense loop not running (fa didn’t start it, or it exited), or controller unreachable so every call fails. Check: sense runner running (`fa check` shows `sense: running`), `.fa_sense.log` for errors.

### 5. world_state.json

- Single file. **Sense loop** writes it; **dashboard** reads it.
- Both default to the same path only if they use the same `WORLD_STATE_PATH` (or both leave it unset). Default = directory of the script + `world_state.json` (agent_scripts when run from repo).
- **If this fails:** File missing → dashboard shows "no file". File stale (mtime old) → position static. Check: file exists under `factorio/agent_scripts/world_state.json`, `ls -la` mtime updates every ~0.25s when sense loop is healthy.

### 6. dashboard.py

- **dashboard.py** `_load_world_state()` reads `WORLD_STATE_PATH` (default = `Path(__file__).resolve().parent / "world_state.json"` = agent_scripts).
- **build_dashboard()** uses `state.get("players") or []`; each player needs `position.x`, `position.y` for the Players table.
- **If this fails:** Wrong path (different `WORLD_STATE_PATH` when running dashboard vs sense_loop), or JSON invalid. Check: run dashboard from same env/cwd as where sense_loop was started, or set same `WORLD_STATE_PATH` for both.

## When position is static

1. **Sense loop not running**  
   Run `fa check`. If `sense: not running`, run `fa` or `fa check` (CONTROLLER_URL is in .zshrc) so the sense loop can start, or start it manually.

2. **Controller unreachable from sense loop**  
   Sense loop runs on the machine where you ran `fa`; it uses CONTROLLER_URL (e.g. http://192.168.0.158:8080). If that URL isn’t reachable (firewall, wrong host), requests fail. Check `.fa_sense.log` and `curl -s http://192.168.0.158:8080/health` / `curl -s http://192.168.0.158:8080/players`.

3. **GET /players returns []**  
   RCON not connected, or no connected player with character. Check controller health (rcon ok) and that you’re in game with a character.

4. **Different WORLD_STATE_PATH**  
   Sense loop and dashboard must use the same path. Don’t set `WORLD_STATE_PATH` for one and leave it unset for the other, or set both to the same path.

5. **File not updating**  
   Check `world_state.json` mtime; if it doesn’t change every few seconds, the sense loop isn’t writing (crashed, not started, or controller errors). Check `.fa_sense.log`.

## Quick checks

```bash
# Controller and players (URL prefilled — controller has static lease)
curl -s http://192.168.0.158:8080/health
curl -s http://192.168.0.158:8080/players

# Sense loop running and file path
fa check
ls -la ~/dotfiles/factorio/agent_scripts/world_state.json
tail -20 ~/dotfiles/factorio/agent_scripts/.fa_sense.log
```

## Position static? Checklist

1. **Sense loop running?** `fa check` → `sense: running`. If not, run `fa` or `fa check` (CONTROLLER_URL is in .zshrc).
2. **Controller reachable?** `curl -s http://192.168.0.158:8080/health` returns JSON. If not, fix network / URL.
3. **Players from game?** `curl -s http://192.168.0.158:8080/players` returns `[{ "name": "...", "position": { "x": ..., "y": ... } }]` when you’re in game with a character. If `[]`, RCON or game state issue.
4. **Same file for sense and dashboard?** Don’t set `WORLD_STATE_PATH` for one and not the other; default is `agent_scripts/world_state.json`.
5. **File updating?** `ls -la` on `world_state.json` — mtime should change every few seconds. If not, check `.fa_sense.log` for errors.

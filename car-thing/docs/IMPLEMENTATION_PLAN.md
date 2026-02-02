# Car Thing Implementation Plan (Agent-Oriented)

Incremental delivery: one feature at a time. **Agent** = Cursor AI with read/write/run_terminal tools. Agent performs all coding and tool calls. After each phase: verify new feature, re-verify all previous, then checkpoint.

---

## Agent Workflow

**Before starting any phase:**
1. Read `project_context.md` and this file.
2. If `project_context.md` has `car_thing_current_phase`, start from that phase; otherwise start at Phase 0.
3. Complete phases in order. Do not skip.

**Per-phase cycle:**
1. **Preflight** — Read listed files; run listed checks.
2. **Steps** — Execute each step (create/edit files, run commands).
3. **Verify** — Run verification commands; record results.
4. **Regression** — Re-run verification for all previous phases.
5. **Checkpoint** — Update `project_context.md` with `car_thing_current_phase: N`, date, and next steps.

**If verification fails:** Fix the failure before checkpointing. Do not advance phase.

**Checkpoint format:** Append to `project_context.md` under Session Records:
```
### Car Thing Phase N - [Phase Name]
- **Date**: [auto]
- **car_thing_current_phase**: N
- **Status**: Complete
- **Verification**: [brief note]
- **Next**: Phase N+1 - [name]
```

---

## Phase 0: HTTP Bridge (Foundation)

**Goal:** HTTP server on port 8765 that DeskThing app server can reach. Health endpoint only.

### Preflight
- Read: `hammerspoon/init.lua` (module loading pattern), `car-thing/deskthing-app/server/index.ts` (bridge URL, call pattern).
- Check: `hammerspoon/modules/car-thing-bridge.lua` does not exist (Phase 0 only).

### Steps

1. **Create** `hammerspoon/modules/car-thing-bridge.lua`:
   - Follow pattern of `modules/caffeine.lua`: return table with `init` and `cleanup`.
   - In `init`: create `hs.httpserver.new()`, call `:setPort(8765)`, `:setInterface("loopback")`, `:setCallback(fn)`, `:start()`.
   - Callback: check `method` and `path`; for `GET /health` → respond 200, `Content-Type: application/json`, body `{"ok":true}`.
   - For `POST /macro` and `POST /control` → parse body with `hs.json.decode`; respond 200; log method, path, body.
   - In `cleanup`: stop server if reference exists.

2. **Edit** `hammerspoon/init.lua`:
   - Add `"modules.car-thing-bridge"` to the `modules` table (after other modules).

3. **User action:** Reload Hammerspoon (menu → Reload Config, or hyper+r). Bridge starts on init.

### Verification (Agent-Runnable)
```bash
curl -s http://127.0.0.1:8765/health
# Expected: {"ok":true} or similar JSON with ok:true

curl -s -X POST http://127.0.0.1:8765/macro -H "Content-Type: application/json" -d '{"id":"test"}'
# Expected: 200 response
```

### Verification (User-Manual)
- Reload Hammerspoon (Hammerspoon menu → Reload Config).
- Confirm no errors in Hammerspoon console.

### Regression
- None (first phase).

### Checkpoint
- Set `car_thing_current_phase: 0` in `project_context.md`.
- Note: "Bridge health and POST endpoints respond."

---

## Phase 1: Macro Execution

**Goal:** Tapping a macro button runs the configured action on the Mac.

### Preflight
- Read: `hammerspoon/modules/car-thing-bridge.lua`, `car-thing/config/macros.example.json`, `car-thing/deskthing-app/server/index.ts`.
- Check: Phase 0 verification passes (`curl http://127.0.0.1:8765/health`).

### Steps

1. **Create or copy** `car-thing/config/macros.json`:
   - Copy from `macros.example.json` if needed.
   - Ensure at least one macro with `type: "applescript"` and simple payload (e.g. `display dialog "Hello"`).
   - Format: `{ "macros": [ { "id": "...", "label": "...", "type": "applescript"|"shortcut", "payload": "..." } ] }`.

2. **Edit** `hammerspoon/modules/car-thing-bridge.lua`:
   - On `POST /macro` with body `{ id }`: load macros from config file. Resolve path: `hs.configdir .. "/../car-thing/config/macros.json"` or use absolute path from dotfiles root.
   - Find macro by `id`. If not found, respond 404.
   - If `type == "applescript"`: run `hs.execute('osascript -e ' .. hs.json.encode(payload))` (escape properly for shell).
   - If `type == "shortcut"`: run `hs.execute('shortcuts run "' .. payload .. '"')`.
   - Run in background (non-blocking); respond 200 immediately.
   - Log execution result for debugging.

3. **Verify** macros.json path: Bridge must read from dotfiles. Use `hs.configdir` to resolve `~/.hammerspoon`; dotfiles may be symlinked. Prefer path like `hs.configdir .. "/../car-thing/config/macros.json"` or explicit `os.getenv("HOME") .. "/dotfiles/car-thing/config/macros.json"` if dotfiles at `~/dotfiles`.

### Verification (Agent-Runnable)
```bash
# Add test macro to macros.json if not present: id "test", type "applescript", payload "display dialog \"Hello\""
curl -s -X POST http://127.0.0.1:8765/macro -H "Content-Type: application/json" -d '{"id":"test"}'
# Expected: 200
# User will see dialog if running with GUI
```

### Verification (User-Manual)
- Reload Hammerspoon.
- Run `curl` above; a "Hello" dialog should appear (if macOS GUI session).
- Or: DeskThing app running, tap macro on Car Thing → action runs.

### Regression
- `curl http://127.0.0.1:8765/health` → still 200.

### Checkpoint
- Set `car_thing_current_phase: 1`.
- Note: "Macro execution works; bridge health still works."

---

## Phase 2: Mic Mute

**Goal:** Control tab mic mute toggle mutes/unmutes the Mac microphone.

### Preflight
- Read: `hammerspoon/modules/car-thing-bridge.lua`, `car-thing/deskthing-app/src/tabs/ControlTab.tsx`, `car-thing/deskthing-app/server/index.ts`.
- Check: Phases 0 and 1 verification pass.

### Steps

1. **Edit** `hammerspoon/modules/car-thing-bridge.lua`:
   - On `POST /control` with body `{ action, value }`:
   - If `action == "mic-mute"`: get default input via `hs.audiodevice.defaultInputDevice()`, call `setInputMuted(value)`.
   - Respond 200. Log errors if device is nil.

2. **Verify** app already sends `control` with `action: "mic-mute"` and `value: boolean` — no app changes needed unless ControlTab does not send correctly.

### Verification (Agent-Runnable)
```bash
# Mute
curl -s -X POST http://127.0.0.1:8765/control -H "Content-Type: application/json" -d '{"action":"mic-mute","value":true}'
# Unmute
curl -s -X POST http://127.0.0.1:8765/control -H "Content-Type: application/json" -d '{"action":"mic-mute","value":false}'
# Expected: 200 each
```

### Verification (User-Manual)
- Check System Settings → Sound → Input: mute state should change after curl.
- Or: Toggle mic mute on Car Thing Control tab → system mic mutes/unmutes.

### Regression
- Phase 0: `curl /health`.
- Phase 1: `curl -X POST .../macro -d '{"id":"test"}'`.

### Checkpoint
- Set `car_thing_current_phase: 2`.

---

## Phase 3: Master Volume

**Goal:** Volume slider in Control tab adjusts system output volume.

### Preflight
- Read: `hammerspoon/modules/car-thing-bridge.lua`, `car-thing/deskthing-app/src/tabs/ControlTab.tsx`, `car-thing/deskthing-app/server/index.ts`.
- Check: Phases 0–2 pass.

### Steps

1. **Edit** `hammerspoon/modules/car-thing-bridge.lua`:
   - On `POST /control` with `action == "volume"` and `value` (0–100): run `osascript -e 'set volume output volume ' .. value` (or use `hs.audiodevice` if available for volume).
   - Respond 200.

2. **Edit** `car-thing/deskthing-app/src/tabs/ControlTab.tsx`:
   - Add volume state (0–100).
   - Add slider (use Radix Slider or HTML range input; style per design bible).
   - On change: call `DeskThing.send({ type: 'control', payload: { action: 'volume', value } })`.
   - Optionally fetch current volume from bridge on mount (add `GET /audio/volume` if needed); otherwise start at 50 or last known.

### Verification (Agent-Runnable)
```bash
curl -s -X POST http://127.0.0.1:8765/control -H "Content-Type: application/json" -d '{"action":"volume","value":50}'
# Expected: 200; system volume changes
```

### Verification (User-Manual)
- Adjust volume slider on Car Thing → system volume changes.

### Regression
- Phases 0, 1, 2.

### Checkpoint
- Set `car_thing_current_phase: 3`.

---

## Phase 4: Output Device Switch

**Goal:** Select default audio output from Control tab.

### Preflight
- Read: `hammerspoon/modules/car-thing-bridge.lua`, `car-thing/deskthing-app/src/tabs/ControlTab.tsx`.
- Check: Phases 0–3 pass.

### Steps

1. **Edit** `hammerspoon/modules/car-thing-bridge.lua`:
   - Add `GET /audio/devices` → return JSON array of `{ id, name }` for output devices. Use `hs.audiodevice.allOutputDevices()`.
   - On `POST /control` with `action == "output-device"` and `value` (device id): set default output via `hs.audiodevice` API.
   - Respond 200.

2. **Edit** `car-thing/deskthing-app/server/index.ts`:
   - On app start or when Control tab mounts: fetch `GET ${BRIDGE_URL}/audio/devices`, send to client via `DeskThing.send({ type: 'audio-devices', payload })` (or client fetches if same-origin). Document the flow.
   - Client needs to request devices; server can fetch on a `get-audio-devices` request from client.

3. **Edit** `car-thing/deskthing-app/src/tabs/ControlTab.tsx`:
   - Add device list state.
   - Add `DeskThing.on('audio-devices', ...)` to receive list.
   - On mount: send `DeskThing.send({ type: 'get-audio-devices' })` (server handles and responds).
   - Add dropdown or button list for device selection.
   - On select: send `DeskThing.send({ type: 'control', payload: { action: 'output-device', value: id } })`.

4. **Edit** `car-thing/deskthing-app/server/index.ts`:
   - Handle `get-audio-devices`: fetch from bridge, send to client.

### Verification (Agent-Runnable)
```bash
curl -s http://127.0.0.1:8765/audio/devices
# Expected: JSON array of devices

curl -s -X POST http://127.0.0.1:8765/control -H "Content-Type: application/json" -d '{"action":"output-device","value":"<valid-id>"}'
# Expected: 200
```

### Verification (User-Manual)
- Select different output on Car Thing → default output changes.

### Regression
- Phases 0–3.

### Checkpoint
- Set `car_thing_current_phase: 4`.

---

## Phase 5: miniDSP Control (Optional)

**Goal:** Control miniDSP USB DAC if minidsp-rs is running.

### Preflight
- Read: minidsp-rs HTTP API (localhost:5380) or CLI.
- Check: Phases 0–4 pass. Skip if no miniDSP hardware.

### Steps

1. **Edit** `hammerspoon/modules/car-thing-bridge.lua`:
   - Add proxy handlers: `POST /minidsp/volume`, `POST /minidsp/preset`, etc. Forward to `http://127.0.0.1:5380` or call minidsp CLI.
   - Use `hs.http.asyncPost` or `hs.execute` with curl.

2. **Edit** `car-thing/deskthing-app/src/tabs/ControlTab.tsx`:
   - Add miniDSP section (volume, preset buttons).
   - Send control events; server forwards to bridge; bridge forwards to minidsp.

3. **Edit** `car-thing/deskthing-app/server/index.ts`:
   - Handle minidsp control events; call bridge `/minidsp/*` endpoints.

### Verification
- Change miniDSP preset/volume from Car Thing → hardware responds.

### Regression
- Phases 0–4.

### Checkpoint
- Set `car_thing_current_phase: 5`.

---

## Phase 6: Notifications (First Source)

**Goal:** Display one notification source in Notifications tab.

### Preflight
- Read: `car-thing/deskthing-app/src/tabs/NotificationsTab.tsx`, `car-thing/deskthing-app/server/index.ts`.
- Check: Phases 0–5 pass.

### Steps

1. **Create** Mac fetcher service or extend bridge:
   - Option A: Add to bridge a background task that fetches RSS/calendar; expose `GET /notifications`.
   - Option B: Separate script (Python/Node) that writes to a file; bridge reads and serves.
   - Return JSON: `{ items: [ { id, title, summary, url, source, timestamp } ] }`.

2. **Edit** `car-thing/deskthing-app/server/index.ts`:
   - On interval or on client request: fetch `GET ${BRIDGE_URL}/notifications` (or from fetcher service).
   - Send to client: `DeskThing.getInstance().sendDataToClient({ type: 'notifications', payload })` (broadcasts to connected client).

3. **Edit** `car-thing/deskthing-app/src/tabs/NotificationsTab.tsx`:
   - On mount: request notifications (or listen for `notifications` event from server).
   - Render list of items. Use design components (Card, etc.).

### Verification
- Notifications tab shows items from configured source.

### Regression
- Phases 0–5.

### Checkpoint
- Set `car_thing_current_phase: 6`.

---

## Phase 7+: Additional Features

Same pattern for each:
- **Phase 7:** More notification sources.
- **Phase 8:** Dynamic macro list from server.
- **Phase 9:** Audio scene presets.
- **Phase 10:** Home Assistant.
- **Phase 11:** n8n webhooks.
- **Phase 12:** Atlas (when TTS ready).

---

## File Reference

| Phase | Create | Edit |
|-------|--------|------|
| 0 | `hammerspoon/modules/car-thing-bridge.lua` | `hammerspoon/init.lua` |
| 1 | `car-thing/config/macros.json` | `car-thing-bridge.lua` |
| 2 | — | `car-thing-bridge.lua` |
| 3 | — | `car-thing-bridge.lua`, `ControlTab.tsx` |
| 4 | — | `car-thing-bridge.lua`, `server/index.ts`, `ControlTab.tsx` |
| 5 | — | `car-thing-bridge.lua`, `server/index.ts`, `ControlTab.tsx` |
| 6 | Fetcher (optional) | `car-thing-bridge.lua` or fetcher, `server/index.ts`, `NotificationsTab.tsx` |

---

## Bridge API Summary

| Method | Path | Body | Phase |
|--------|------|------|-------|
| GET | `/health` | — | 0 |
| POST | `/macro` | `{ id }` | 1 |
| POST | `/control` | `{ action, value }` | 2+ |
| GET | `/audio/volume` | — | 3 |
| GET | `/audio/devices` | — | 4 |
| GET | `/audio/mic-muted` | — | 2 |
| GET | `/notifications` | — | 6 |

---

## Gaps, Assumptions & Prerequisites

### Prerequisites (verify before Phase 0)

- **Hammerspoon** installed and running. Config at `~/.hammerspoon/`; modules loadable via `require("modules.X")`. If using `scripts/system/link`, ensure `hammerspoon/modules/` is reachable (full dir symlink or add module files to link mappings).
- **Dotfiles layout:** Workspace at `/Users/pete/dotfiles`. `car-thing/config/` exists. Bridge will resolve macros path relative to dotfiles (see below).
- **DeskThing Server** installed. Car Thing connected or emulator available for later phases.
- **Port 8765** free. Bridge binds to loopback only for security.

### hs.httpserver Callback Signature

Callback receives: `(method, path, headers, body)`. Returns: `(responseBody, statusCode, headersTable)`.

Example: `local body, code, headers = callback(method, path, reqHeaders, reqBody)`.

### macros.json Path Resolution

`hs.configdir` = `~/.hammerspoon`. Dotfiles may be at `~/dotfiles` with hammerspoon as subdir. Try in order:

1. `hs.configdir .. "/../car-thing/config/macros.json"` (if configdir resolves to dotfiles/hammerspoon)
2. `os.getenv("HOME") .. "/dotfiles/car-thing/config/macros.json"`
3. Fallback: log error, respond 500

Add `car-thing/config/macros.json` to `.gitignore` if it contains user-specific shortcuts; keep `macros.example.json` committed.

### AppleScript Payload Escaping

Payload may contain quotes. Safer: write payload to temp file, run `osascript /tmp/script.scpt`. Or escape single quotes for shell: `payload:gsub("'", "'\"'\"'")` before passing to `osascript -e`.

### hs.audiodevice Mic Mute (Phase 2)

Use `device:setInputMuted(value)`. **Known issue (Monterey+):** On some macOS versions, `setInputMuted(true)` on default input can also mute output. Fallback: use AppleScript `input volume 0` / `input volume 100` if available, or document the limitation.

### Server → Client Communication

DeskThing server uses `DeskThing.getInstance().sendDataToClient({ type, payload })` — single arg, broadcasts to client. No socketId. Client listens via `DeskThing.on('audio-devices', ...)` etc.

### Server GET Requests

`callBridge` in server is POST-only. For Phase 4/6, add `getBridge(path)` or `fetch(\`${BRIDGE_URL}${path}\`)` with `method: 'GET'` for `/audio/devices` and `/notifications`.

### Phase 3 Volume Slider

No `@radix-ui/react-slider` installed. Either: `npm install @radix-ui/react-slider`, or use native `<input type="range">` styled per design bible.

### Phase 4 Device ID

Use `hs.audiodevice` device UID (from `device:uid()`) as the `value` for `output-device`. Return `{ id: device:uid(), name: device:name() }` from `/audio/devices`.

### Bridge Security

Call `server:setInterface("loopback")` or `setInterface("127.0.0.1")` before `start()` so the bridge is not exposed on the network.

### Hammerspoon Reload

Agent cannot reliably reload Hammerspoon. Step: "User must reload config (Hammerspoon menu → Reload Config, or hyper+r) after bridge changes." Verification curl commands can run without reload if bridge was already started in a previous session.

### Control Tab Mic State Sync (Phase 2)

Control tab shows mic mute toggle but does not fetch initial state from Mac. On mount, consider: bridge exposes `GET /audio/mic-muted`, server fetches and sends to client, or client requests it. Otherwise toggle may be out of sync with actual state until first user interaction.

### Bridge URL (DeskThing Server)

Server uses `process.env.CAR_THING_BRIDGE_URL || 'http://127.0.0.1:8765'`. DeskThing may not pass env vars to app servers. If bridge is unreachable, verify DeskThing is passing env or hardcode fallback in server.

### DeskThing Server Request Flow

Server runs inside DeskThing process. Client sends via `DeskThing.send()`; server receives via `DeskThing.on()`. Server calls bridge with `fetch()`. Node 18+ has native fetch.

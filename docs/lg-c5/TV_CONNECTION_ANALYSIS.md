# Why the TV Connection Almost Never Works

**Date:** 2026-02-07  
**Scope:** LG C5 (42") @ 192.168.0.39 — Hammerspoon integration

---

## Executive Summary

The TV connection fails for multiple, compounding reasons:

1. **Hammerspoon commands never reach the TV** — Critical bug: `lg-server` does not read the command file
2. **TV may not respond to port 9761** — Per your docs, Network IP Control gets "no response"
3. **TV must be ON** — Port 9761 is only open when the TV is powered on
4. **Possible TV settings** — SDDP and/or LG Connect Apps might need to be enabled

---

## Root Cause 1: Command File Never Read (Critical Bug)

**Hammerspoon writes commands here:** `/tmp/lg-server-command.json`

**`lg-server` behavior:** It has **no code** that reads this file.

Flow today:

1. You press hotkey or use menu → Hammerspoon calls `sendServerCommand("volume_up")`
2. Hammerspoon writes `{"command":"volume_up",...}` to `/tmp/lg-server-command.json`
3. `lg-server` is running but never reads that file
4. The command queue in `lg-server` is only filled by its internal `_monitor_worker` (periodic `query_volume`)

So menu and hotkey commands are written to disk and then ignored.

**Fix:** ✅ **Implemented** — Added `_command_file_worker()` to `lg-server` that polls the command file every 0.5s, queues valid commands, and clears the file after processing. Restart `lg-server` to pick up the fix.

---

## Root Cause 2: TV Protocol / Port 9761

From your docs (`lg-c5-status-summary.md`):

- **Network IP Control (port 9761):** No response to any commands
- **webOS API (port 3000):** Connection reset by peer
- **webOS API (port 3001):** Connects but no response

So even if `lg-server` sent commands correctly, the TV may not respond. Possible reasons:

- SDDP might be OFF (`lg-c5-sddp-fix.md`) — SDDP can be required for network control
- LG Connect Apps might be disabled (`lg-c5-home-assistant-missing.md`) — different from “Network IP Control”
- Firmware or model variant may limit IP control

---

## Root Cause 3: TV Must Be On

`lg-start` checks connectivity before starting:

```bash
if ! nc -z -w5 "$LG_IP" 9761; then
    echo "❌ Cannot connect to $LG_IP:9761"
    echo "Make sure:"
    echo "  - TV is powered on"
```

Port 9761 is typically only open when the TV is powered on. If the TV is off:

- `lg-server` cannot connect
- Status stays `DISCONNECTED`
- Commands could not be sent even if the command file were read

---

## Root Cause 4: Which Script Is Used?

- **Hammerspoon uses:** `scripts/archive/lg-server` (persistent server, status file, command file)
- **Session records mention:** `scripts/lg-c5/lg-monitor` (CLI, connects per command)

`lg-monitor` talks directly to the TV; `lg-server` maintains a persistent connection. Hammerspoon is wired to `lg-server`, which does not consume the command file.

---

## Recommended Fixes (in order)

### 1. Add command-file reader to `lg-server` (must fix)

Add a worker that:

1. Polls `/tmp/lg-server-command.json` periodically (e.g. every 0.5–1 s)
2. Reads and parses the JSON
3. Maps the `command` field to the internal command names (`power_on`, `volume_up`, etc.)
4. Calls `queue_command(...)` for each command
5. Clears or truncates the file after processing so the same command is not repeated

### 2. Verify TV connectivity

Run:

```bash
# TV must be ON
nc -z -w5 192.168.0.39 9761 && echo "Port open" || echo "Port closed"
```

If the port is closed when the TV is on, the TV or network settings are the bottleneck.

### 3. TV settings

From your docs:

- Enable **SDDP** in the hidden menu (8-2-8-8-8)
- Enable **LG Connect Apps** (if present) under Network settings
- Confirm **Network IP Control** is ON

### 4. Consider using `lg-monitor` instead of `lg-server`

`scripts/lg-c5/lg-monitor` connects per command and does not depend on a command file. To use it from Hammerspoon you would:

- Change Hammerspoon to run `lg-monitor <ip> <command>` instead of writing to the command file
- Drop the `lg-server` process for TV control

This would avoid the broken command-file flow but would create a new connection for each action.

---

## Quick Diagnostic Commands

```bash
# 1. Is the TV port open? (TV must be ON)
nc -z -w5 192.168.0.39 9761 && echo "OK" || echo "FAIL"

# 2. Is lg-server running?
pgrep -f lg-server

# 3. What does the status file say?
cat /tmp/lg-server-status.json | jq .

# 4. Recent lg-server log
tail -20 /tmp/lg-server.log

# 5. Manual command test (bypasses Hammerspoon)
~/dotfiles/scripts/lg-c5/lg-monitor 192.168.0.39 volume_up
```

---

## Summary Table

| Issue | Impact | Fix |
|-------|--------|-----|
| lg-server never reads command file | Commands never reach TV | ✅ Fixed — command file worker added |
| TV resets persistent connection | lg-server loses connection on first command | ✅ Fixed — use direct mode (lg-monitor CLI per command) |
| Port 9761 not responding | TV may not support protocol | Check TV settings, SDDP, LG Connect Apps |
| TV off | Port closed, no connection | Use WoL or turn TV on first |
| Wrong script/config | Possible mismatch | Confirm Hammerspoon uses intended script |

## Configuration: useDirectMode

**Default: `useDirectMode = true`** in `config.lua`. When enabled, Hammerspoon invokes `scripts/lg-c5/lg-monitor` directly for each command instead of writing to the command file. This is more reliable because:
- The TV was observed to reset persistent connections when lg-server sent commands
- lg-monitor uses fresh connect → send → disconnect per command, which works

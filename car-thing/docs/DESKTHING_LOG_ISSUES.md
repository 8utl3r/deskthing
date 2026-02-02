# DeskThing Log Issues

Logs live at `car-thing/deskthing-logs/` (symlinked from `~/Library/Application Support/deskthing/logs`). View: `tail -f car-thing/deskthing-logs/application.log.json` or `readable.log.*`.

## Issues Found (from log analysis)

### 1. Device RFCWC0PXXYV — ADB version/file errors

**Symptom:** DeskThing fails to get device info for `RFCWC0PXXYV`:
- `cat: /etc/superbird/version: No such file or directory`
- `cat: /sys/class/efuse/usid: No such file or directory`
- `Failed to get device version`

**Cause:** DeskThing expects Superbird/Thing Labs paths. This device may be:
- Different hardware (e.g. phone, tablet, emulator)
- Different firmware (stock Spotify vs Thing Labs)
- A Car Thing with non-standard firmware

**Action:** If RFCWC0PXXYV is a second Car Thing, ensure it’s flashed with Thing Labs OS. If it’s another device type, you can ignore or disconnect it. Run `./car-thing/scripts/fix-device-connection.sh` — blacklists RFCWC0PXXYV, resets ADB, restarts DeskThing. Car Thing: `8557R08RQ01Q`.

---

### 2. No audio source

**Symptom:** Repeated `No audio source found. Please install an audio app.`

**Cause:** DeskThing looks for an audio playback app (Spotify, Local Audio, etc.) for the landing/music UI. Our `deskthing-dashboard` is a control app, not an audio source.

**Action:** Expected if you’re not using Spotify or Local Audio. Install an audio app from Downloads if you want music on the landing screen, or ignore if you only use our dashboard.

---

### 3. Stats registration — 403 Forbidden

**Symptom:** `Failed to register client: 403 - Forbidden` when registering with DeskThing stats server.

**Cause:** DeskThing backend rejecting registration (auth, rate limit, or server-side config).

**Action:** DeskThing app behavior is unaffected. Report to DeskThing if you care about stats/analytics.

---

## Log Files

| File | Purpose |
|------|---------|
| `application.log.json` | Current log (JSON lines) |
| `application.log.json.<timestamp>` | Rotated logs |
| `readable.log.<timestamp>` | Human-readable format |

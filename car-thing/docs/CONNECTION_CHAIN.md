# Car Thing Connection Chain

How the Car Thing app talks to the Mac, and where to look when something fails.

---

## App works but nothing happens on Mac

If the Car Thing app loads and you can tap volume/macros/mic, but nothing changes on your Mac:

1. **Start Hammerspoon** (if it’s not running): open the Hammerspoon app.
2. **Reload the config** so the bridge starts: Hammerspoon menu → **Reload Config**, or press your reload hotkey (e.g. hyper+R).
3. **Check the bridge:** from repo root run `./car-thing/scripts/verify-bridge.sh`. You want: port 8765 in use, GET /health → 200, POST /control → 200.
4. Try the Car Thing again (volume slider, macro, mic mute).

If the script still reports "Port 8765 not in use", Hammerspoon didn’t start the bridge (check Hammerspoon Console for errors). Once the bridge is listening, the app will control your Mac.

---

## Bridge works from Mac but not from device

If `./car-thing/scripts/verify-bridge.sh` passes and **curl from the Mac** changes volume:

```bash
curl -s -X POST http://127.0.0.1:8765/control -H "Content-Type: application/json" -d '{"action":"volume","value":50}'
```

but using the **Car Thing** (slider, macro, mic) does nothing, the break is **device → DeskThing Server** (events not reaching the bridge).

1. **Check DeskThing Server logs**  
   When you tap volume/macro/mic on the device, the app server should log e.g. `[control] volume 50` or `[macro] test`. If you see **"Bridge /control error"** or **"Bridge /control failed"**, the server is receiving but can’t reach the bridge (wrong URL or network). If you see **no logs at all** when tapping, the server isn’t receiving (wrong app, or DeskThing not routing to our server).

   Where to see logs: DeskThing app on Mac → often under **Settings**, **Help**, or **View → Logs / Console**. Check the docs or Discord for “where are server logs”.

2. **Confirm the right app is active**  
   In DeskThing, ensure **"Dotfiles Car Thing App"** is the app running on the device (not another app like Spotify or Weather).

3. **Restart DeskThing**  
   Quit DeskThing completely and reopen it, then open our app on the device again. Sometimes the server bundle is only loaded on first use.

---

## Audio: master volume only (no per-app mixing)

**Hammerspoon cannot mix volumes from different sources.** The `hs.audiodevice` module controls only the **default output device** (system master volume). There is no API for per-application volume (e.g. Spotify at 80%, Browser at 50%).

**If you need per-app mixing:** use macOS Sound settings (Output → per-app in Sonoma+), or third-party tools like [SoundSource](https://rogueamoeba.com/soundsource/), [Loopback](https://rogueamoeba.com/loopback/), or BlackHole + a mixer. The Car Thing bridge will continue to control **master** volume only.

---

## Data Flow (Volume Example)

```
[Car Thing device]
  → LiteClient (runs our app in webview)
  → User taps volume slider
  → React: DeskThing.send({ type: 'control', payload: { action: 'volume', value: 50 } })
  → postMessage to LiteClient
  → LiteClient forwards to DeskThing Server (Mac) over ADB/network

[DeskThing Server on Mac]
  → Loads our app server bundle (server/index.js)
  → DeskThing.on('control') receives event
  → callBridge('/control', { action: 'volume', value: 50 })
  → fetch('http://127.0.0.1:8765/control', { method: 'POST', body: ... })

[Hammerspoon bridge]
  → hs.httpserver on port 8765 (loopback only)
  → POST /control → parse body → action 'volume' → osascript 'set volume output volume 50'
  → return 200
```

---

## Failure Points

| Layer | Symptom | How to verify |
|-------|---------|----------------|
| **1. Bridge not running** | curl to 8765 fails (connection refused) | `curl -s http://127.0.0.1:8765/health` |
| **2. Bridge module not loaded** | Hammerspoon reloads but port not open | Hammerspoon Console: look for "Car Thing bridge" or "Failed to initialize modules.car-thing-bridge" |
| **3. Bridge file broken** | require() fails (e.g. ELOOP if symlink to self) | `ls -la ~/.hammerspoon/modules/car-thing-bridge.lua` and `file` it; must be regular file or valid symlink to real file |
| **4. DeskThing server not calling bridge** | Bridge works from curl but not from device | DeskThing Server logs (where it runs); our server logs "[control]" and "Bridge /control failed" or "Bridge /control error" |
| **5. Client not sending** | Server never logs [control] | App loaded on device? Correct tab? DeskThing.send() called? |
| **6. LiteClient ↔ Server** | Device and Mac not connected | DeskThing shows device; ADB or network path up |

---

## Symlink Trap (Your Setup)

If `~/.hammerspoon/modules` is a **symlink** to `~/dotfiles/hammerspoon/modules`, then:

- **Do not** add a per-file link for `car-thing-bridge.lua` in the link script.
- Creating a link at `~/.hammerspoon/modules/car-thing-bridge.lua` → `.../dotfiles/.../car-thing-bridge.lua` **overwrites the real file** (dest resolves to the same path as src), leaving a **self-referential symlink** and ELOOP.
- **Fix:** Add new modules only in dotfiles; they appear automatically under `~/.hammerspoon/modules`.

---

## Verification Script

Run from repo root:

```bash
./car-thing/scripts/verify-bridge.sh
```

Checks: port 8765 listening, GET /health, POST /control, and reports each step.

---

## Server-Side Logging

The app server (DeskThing) logs:

- `[control] action value` when it receives a control event.
- `Bridge /control failed: STATUS` when the bridge returns non-2xx.
- `Bridge /control error: ERR` when fetch throws (e.g. connection refused).

So: if you see `[control] volume 50` but no "Bridge ..." error, the server is calling the bridge and the bridge is returning 2xx. If you see "Bridge /control error: fetch failed" or similar, the bridge is not reachable (not running or wrong URL).

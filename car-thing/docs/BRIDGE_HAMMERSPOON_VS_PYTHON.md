# Car Thing Bridge: Hammerspoon vs Python / Native

Why we use Hammerspoon for the bridge, what we’d gain or lose by switching to a Python (or other) controller, and why volume felt slow before.

---

## Why Volume Felt Slow

Previously the bridge set system volume by **spawning `osascript`** for every change. Each call does:

- HTTP request → Hammerspoon → `hs.execute("osascript -e 'set volume ...'")` → new process → AppleScript → system.

That process spawn adds tens of milliseconds per change. We’ve **removed that**: the bridge now uses **`hs.audiodevice.defaultOutputDevice():setVolume(vol)`** and **`:volume()`** for GET, so volume get/set is in-process and much faster. If it still feels slow, the remaining cost is likely **network** (device → DeskThing Server → our server → bridge) or **throttling** (we limit slider updates to ~20/sec); the bridge itself is no longer the main bottleneck.

---

## Benefits of Hammerspoon

- **Already there** – You use it for window management, hotkeys, etc. No extra daemon or install.
- **Single automation layer** – One config (and one process) for Car Thing bridge, hotkeys, window rules, etc.
- **Native volume API** – `hs.audiodevice` talks to macOS audio without subprocesses; latency is low.
- **Easy to extend** – Add more endpoints (e.g. macros that trigger Hammerspoon actions) without another stack.
- **Fits dotfiles** – Config lives in `~/.hammerspoon` (or your dotfiles); versioned and reloadable.

---

## What We’d Gain by Switching (e.g. Python)

- **Possibly simpler** – One small Python script that only does the bridge (HTTP + volume/macros). No Lua, no Hammerspoon reload.
- **Same or similar latency** – If the Python server used PyObjC/ScriptingBridge or subprocess `osascript`, you’d get comparable (or slightly worse) latency than current Hammerspoon + `hs.audiodevice`. The main win was dropping osascript; we already did that in Hammerspoon.
- **No dependency on Hammerspoon** – If you ever stop using Hammerspoon, the Car Thing could still work with a standalone bridge.

---

## What We’d Lose by Switching

- **Two automation systems** – You’d run both Hammerspoon (for everything else) and a separate bridge process.
- **No shared context** – Macros or future features can’t trivially call Hammerspoon APIs (e.g. window moves, hotkey triggers) from the same process; you’d need IPC or duplicate logic.
- **Extra process** – Install, run at login, and maintain a Python (or Node) bridge; Hammerspoon is already running and reloadable.

---

## When a Separate Bridge Might Make Sense

- You want to **stop using Hammerspoon** but keep the Car Thing.
- You need **per-app volume** or other APIs Hammerspoon doesn’t expose (e.g. SoundSource, Loopback); a custom daemon could integrate those.
- You’re optimizing for **minimal latency** and are willing to use a Unix socket or native API from Python/Node instead of HTTP; even then, most of the delay is device → server → Mac, not the last hop.

---

## Summary

Hammerspoon is **not inherently too slow** for this. The slow part was **osascript**; we fixed that by using **`hs.audiodevice`**. Keeping the bridge in Hammerspoon keeps one automation stack, uses a fast native volume API, and fits your current setup. Switching to Python (or another controller) would mainly trade a single stack for a dedicated bridge process and extra maintenance, with little or no latency gain if the new bridge still used HTTP and similar APIs.

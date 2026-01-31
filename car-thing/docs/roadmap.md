# Car Thing App Roadmap

Vision and architecture for the Dotfiles Car Thing app. The app runs on the device; the **server** (in DeskThing Server on your Mac) does the heavy lifting—HTTP calls, AppleScript, shell commands.

---

## Core Feature Areas

### 1. Computer Control (framework first)

**Architecture:** Car Thing UI → DeskThing app server → Mac services (HTTP, AppleScript, shell).

| Capability | Mac-side | Status |
|------------|----------|--------|
| Mic mute | Hammerspoon `hs.audiodevice` or AppleScript | Framework |
| Volume | Same | Framework |
| Audio source / output device | Hammerspoon `audio-info`-style logic | Framework |
| miniDSP USB DAC | [minidsp-rs](https://github.com/mrene/minidsp-rs) HTTP API (default `localhost:5380`) — volume, mute, presets, input source | Framework |

**Implementation:** Add an HTTP bridge (e.g. Hammerspoon `hs.httpserver` or small Python/Node server) that exposes endpoints like `/audio/mute`, `/audio/volume`, `/minidsp/...`. The app server calls `http://localhost:PORT/...`.

---

### 2. Dynamic Notification Display

**Examples:**
- YouTube channel uploads (RSS or YouTube API)
- GitHub notifications
- Calendar / next meeting
- Weather
- Custom RSS feeds

**Architecture:** A small service on the Mac fetches/aggregates data and exposes it via HTTP. The app polls or uses WebSockets to display it.

---

### 3. Macro Buttons (AppleScript / Shortcuts)

**Architecture:** Car Thing button → app server → `osascript` or `shortcuts run "Shortcut Name"`.

**Server endpoint pattern:**
```
POST /macro/run
Body: { "id": "mute-teams", "type": "applescript" | "shortcut", "payload": "..." }
```

Store macro definitions in config; UI renders buttons from that config.

---

### 4. Atlas + Speech (future)

**Car Thing hardware:** Mic array on top (originally for "Hey Spotify"). Mic access in DeskThing/Thing Labs firmware is TBD—may need custom client or LiteClient support.

**Vision:**
- Push-to-talk or wake word on Car Thing
- Audio streamed to Mac → speech-to-text → Atlas proxy → Ollama
- Response → text-to-speech → streamed back to Car Thing

**Blockers:** Speech synthesis (TTS) in your Atlas pipeline; mic access from the Car Thing client; low-latency audio streaming.

---

## Ideas from Similar Setups

| Idea | Source | Notes |
|------|--------|-------|
| Pomodoro timer | DeskThing (pomodoro-thing) | Focus blocks, good for ADHD |
| Discord mute/deafen | Stream Deck use cases | One-tap mute for calls |
| GitHub PR/issue count | DeskThing-GitHub | Glanceable dev status |
| Sonos / multi-room audio | sonos-webapp | Room selection, volume |
| Stock/sports tickers | DeskThing MarketHub, SportsHub | Glanceable info |
| Lyrics overlay | LyrThing | Sync with Spotify/local audio |
| Radial menus | Stream Deck | Nested actions in limited space |
| Knowledge base launcher | Stream Deck workflows | Quick links to notes, docs |
| Meeting status | Calendar integration | "In meeting" vs "free" |
| Smart home quick actions | Home Assistant | Lights, thermostat from desk |
| Clipboard history | Productivity | Recent copies, paste |
| Quick capture inbox | GTD/ADHD | One-tap "add to inbox" |

---

## Suggested Additions for Your Setup

1. **Focus mode** — One tap: mute mic, dim lights, start Pomodoro, DND.
2. **Meeting mode** — Mute Teams/Zoom, switch audio to headset, show "In meeting".
3. **Atlas quick actions** — Buttons like "Add task", "Log note", "What's next?" that hit Atlas proxy.
4. **Audio scene presets** — "Music" (miniDSP preset X, volume Y), "Call" (headset, mic unmuted), "Podcast".
5. **Home Assistant dashboard** — Lights, climate, media from the Car Thing.
6. **n8n trigger** — Buttons that fire n8n webhooks for custom automations.
7. **Glanceable calendar** — Next 1–2 events, one-tap to join.
8. **System stats** — CPU, RAM, network (from a small Mac agent).

---

## Implementation Order

1. **HTTP bridge on Mac** — Hammerspoon or small server with `/macro/run`, `/audio/mute`, `/audio/volume`.
2. **App structure** — Tabs: Control | Macros | Notifications | (future: Atlas).
3. **Macro buttons** — Config-driven, call bridge to run AppleScript/shortcuts.
4. **Audio control** — Wire bridge to Hammerspoon or `SwitchAudioSource` + volume.
5. **miniDSP** — If minidsp-rs is running, add proxy endpoints or call it from the bridge.
6. **Notifications** — Pick one source (e.g. YouTube RSS), add fetcher + UI.
7. **Atlas** — When TTS is ready, design mic → Atlas → TTS flow.

---

## Files to Create

- `car-thing/docs/roadmap.md` — This file
- `car-thing/deskthing-app/src/tabs/` — Tab components (Control, Macros, Notifications)
- `car-thing/deskthing-app/server/` — Endpoints that call the Mac bridge
- `hammerspoon/modules/car-thing-bridge.lua` — HTTP server for Car Thing (or separate script)
- `car-thing/config/macros.json` — Macro definitions (or in server config)

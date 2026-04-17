# Car Thing Bridge

HTTP server for the DeskThing app to control the Mac: macros, audio, notifications, and RSS feed.

## Overview

- **Port**: 8765 (loopback only)
- **Base URL**: `http://127.0.0.1:8765`
- **Config path**: `~/dotfiles/car-thing/config/` or `~/.hammerspoon/../car-thing/config/`

## API Endpoints

### Health

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Returns `{"ok":true}` |

### Reload

| Method | Path | Description |
|--------|------|-------------|
| GET/POST | `/reload` | Reloads Hammerspoon config (responds first, then reloads) |

### Notifications

| Method | Path | Body | Description |
|--------|------|------|-------------|
| POST | `/notify` | `{"message":"text"}` | Shows macOS notification (e.g. "unassigned" when control has no function) |

### Audio

| Method | Path | Description |
|--------|------|-------------|
| GET | `/audio/devices` | List output devices `{devices: [{id, name}], defaultId}` |
| GET | `/audio/volume` | Current output volume 0–100 `{"volume":N}` |
| GET | `/audio/mic-muted` | Input mute state `{"muted":true|false}` |
| POST | `/control` | See Control actions below |

### Feed

| Method | Path | Description |
|--------|------|-------------|
| GET | `/feed` or `/notifications` | Aggregated RSS items from `feed.json` URLs |

### Macros

| Method | Path | Body | Description |
|--------|------|------|-------------|
| POST | `/macro` | `{"id":"macro-id"}` | Run macro by ID from `macros.json` |

### Control (POST /control)

| action | value | Description |
|--------|-------|-------------|
| `mic-mute` | boolean | Set input mute |
| `volume` | number 0–100 | Set output volume |
| `output-device` | string UID | Set default output device |

## Config Files

### macros.json

Path: `~/dotfiles/car-thing/config/macros.json`

```json
{
  "macros": [
    {
      "id": "my-macro",
      "type": "applescript",
      "payload": "tell application \"Music\" to play"
    },
    {
      "id": "my-shortcut",
      "type": "shortcut",
      "payload": "My Shortcut Name"
    }
  ]
}
```

- **type**: `applescript` – runs AppleScript; `shortcut` – runs macOS Shortcut by name
- **payload**: Script (applescript) or shortcut name (shortcut)

### feed.json

Path: `~/dotfiles/car-thing/config/feed.json`

```json
{
  "urls": [
    "https://example.com/feed.xml",
    "https://other.com/rss"
  ]
}
```

RSS URLs are fetched and aggregated; items include `title`, `summary`, `url`, `source`, `timestamp`.

## Auto-reload

The bridge watches `~/.hammerspoon/modules/car-thing-bridge.lua` and triggers a Hammerspoon reload when the file changes. Useful with `reload-hammerspoon.sh` and touch-based reload workflows.

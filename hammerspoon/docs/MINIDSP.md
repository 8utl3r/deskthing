# MiniDSP DDRC-24 Hammerspoon Module

Polls status and controls the DDRC-24 via the [minidsp-rs](https://github.com/mrene/minidsp-rs) HTTP API.

## Prerequisites

1. **minidsp-rs daemon** running with HTTP server enabled
2. DDRC-24 connected via USB

### Install minidsp-rs

```bash
./scripts/install-minidsp.sh
```

This installs `minidsp` and `minidspd` to `~/.local/bin`, creates config from `minidsp/config.toml`, and sets up a LaunchAgent so the daemon runs at login.

### Config

`minidsp/config.toml` (linked to `~/.config/minidsp/config.toml`):

```toml
[http_server]
bind_address = "127.0.0.1:5380"
```

## Configuration

In `config.lua`:

```lua
config.minidsp = {
    host = "127.0.0.1",
    port = 5380,
    deviceIndex = 0,       -- First device
    pollInterval = 5,     -- Seconds between status polls
    pollEnabled = true,    -- Start polling on init
    onStatus = function(status)
        -- Optional: run automation when status changes
        -- status.master: preset, source, volume, mute
        -- status.input_levels, status.output_levels
    end,
}
```

## API (from other modules or Hammerflow)

```lua
local minidsp = require("modules.minidsp")

-- Status
minidsp.getStatus()        -- Fetch current status
minidsp.getLastStatus()   -- Cached status from last poll
minidsp.getDevices()      -- List devices
minidsp.isConnected()     -- true if daemon reachable

-- Control
minidsp.setPreset(0)      -- Preset 0-3
minidsp.setSource("Toslink")  -- "Toslink", "Analog", "USB"
minidsp.setVolume(-20)    -- Volume in dB
minidsp.setMute(true)     -- Mute
minidsp.toggleMute()     -- Toggle mute

-- Polling (for automation)
minidsp.startPolling(5, function(status)
    -- Called every 5s when status is fetched
end)
minidsp.stopPolling()

-- Health
minidsp.healthCheck()     -- Returns { healthy, details, errors }
```

## Status shape

```lua
{
    master = {
        preset = 0,        -- 0-3
        source = "Toslink",
        volume = -8.0,     -- dB
        mute = false
    },
    input_levels = { -61.6, -57.9 },
    output_levels = { -67.9, -71.6, -120.0, -120.0 }
}
```

## Example automation

```lua
-- In config: pollEnabled = true, onStatus = function(status) ... end
-- Or manually:
minidsp.startPolling(3, function(status)
    if status.master and status.master.volume > -10 then
        -- Cap volume
        minidsp.setVolume(-10)
    end
end)
```

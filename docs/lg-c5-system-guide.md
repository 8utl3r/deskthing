# LG C5 Control System Documentation

## Overview

Complete IP control system for LG C5 (2025) TV based on Savant Blueprint profile analysis. Features persistent connection, real-time monitoring, and Hammerspoon integration.

## Architecture

### Components

1. **`lg-server`** - Persistent TCP server maintaining connection to TV
2. **`lg-debug`** - Real-time monitoring and debugging tool  
3. **`lg-menu.lua`** - Hammerspoon menu bar integration
4. **`lg-start`** - Startup script with connection testing

### Protocol Details (from Savant Profile)

- **Port**: 9761 (TCP)
- **Send Postfix**: `\x0D` (carriage return)
- **Receive End**: `\x0A` (line feed)  
- **Response Timeout**: 500ms default, 5000ms for queries
- **Encryption**: AES128 (optional - system works without)
- **Keycode**: `QDF6T3HV` (from TV settings)

## Quick Start

### 1. Start the System

```bash
# Start server with connection test
./bin/lg-start 192.168.0.39

# Or start manually
./bin/lg-server 192.168.0.39 &
```

### 2. Monitor Status

```bash
# Real-time monitoring
./bin/lg-debug monitor

# One-time status check
./bin/lg-debug status

# View recent logs
./bin/lg-debug log
```

### 3. Hammerspoon Integration

The menu bar item shows real-time status:
- **📺 LG: ✅ 🔌 🔊25** - Connected, powered on, volume 25
- **📺 LG: ❌ 🔌** - Disconnected, powered off

Click the menu bar item for command options.

## Commands Reference

### Power Control
- `power_on` - Wake-on-LAN + IP control (14s delay)
- `power_off` - Power off via IP control (15s delay)

### Volume Control  
- `volume_up` - Increase volume
- `volume_down` - Decrease volume
- `mute` - Toggle mute/unmute

### Input Switching
- `input_hdmi1` - Switch to HDMI 1
- `input_hdmi2` - Switch to HDMI 2  
- `input_hdmi3` - Switch to HDMI 3
- `input_hdmi4` - Switch to HDMI 4

### Status Queries
- `query_volume` - Get current volume (returns `VOL:XX`)
- `query_power` - Get power status
- `query_input` - Get current input

## Hammerspoon Hotkeys

All hotkeys use `⌘⌥⌃` prefix:

- **P** - Power toggle (on then off)
- **↑/↓** - Volume up/down
- **M** - Mute toggle
- **1-4** - HDMI input 1-4
- **T** - Connection test
- **D** - Open debug monitor

## File Locations

### Status Files
- `/tmp/lg-server-status.json` - Current server status
- `/tmp/lg-server.log` - Server log file
- `/tmp/lg-server-command.json` - Command queue file

### Scripts
- `bin/lg-server` - Main server process
- `bin/lg-debug` - Debug monitoring tool
- `bin/lg-start` - Startup script
- `hammerspoon/lg-menu.lua` - Hammerspoon integration

## Troubleshooting

### Connection Issues

1. **Test basic connectivity**:
   ```bash
   nc -z -w5 192.168.0.39 9761
   ```

2. **Check TV settings**:
   - Settings → Support → IP Control Settings
   - Network IP Control: ON
   - Wake on LAN: ON
   - Generated keycode: `QDF6T3HV`

3. **View server logs**:
   ```bash
   tail -f /tmp/lg-server.log
   ```

### Server Issues

1. **Check if server is running**:
   ```bash
   pgrep -f lg-server
   ```

2. **Restart server**:
   ```bash
   pkill -f lg-server
   ./bin/lg-start 192.168.0.39
   ```

3. **Debug connection**:
   ```bash
   ./bin/lg-debug test --ip 192.168.0.39
   ```

### Hammerspoon Issues

1. **Reload Hammerspoon config**:
   - Press `⌘⌥⌃R` or restart Hammerspoon

2. **Check console for errors**:
   - Open Hammerspoon Console
   - Look for LG Menu errors

3. **Verify menu bar item**:
   - Should show "📺 LG: ..." in menu bar
   - Click to access command menu

## Advanced Usage

### Interactive Command Mode

```bash
./bin/lg-debug interactive
```

Allows sending commands interactively with real-time feedback.

### Custom Commands

Add new commands to `lg-server` by updating the `commands` dictionary:

```python
self.commands = {
    "custom_command": "KEY_ACTION custom",
    # ... existing commands
}
```

### State Tracking

The server tracks these state variables:
- `Power_current_power_setting` (ON/OFF)
- `Volume_current_volume` (0-100)
- `Mute_current_mute_setting` (ON/OFF)  
- `CurrentInput` (HDMI1, HDMI2, etc.)

## Savant Profile Integration

This system implements the Savant Blueprint profile specifications:

- **Protocol**: TCP port 9761 with `\x0D` postfix
- **Timing**: Respects command delays (14s WoL, 15s power off, etc.)
- **Commands**: Uses exact command strings from profile
- **State**: Tracks all state variables defined in profile
- **Encryption**: Supports AES128 (optional for basic operation)

## Performance Notes

- **Connection**: Persistent TCP connection with auto-reconnect
- **Latency**: Commands execute within 500ms (per Savant spec)
- **Reliability**: Automatic reconnection on connection loss
- **Monitoring**: Real-time status updates every 2 seconds
- **Logging**: Comprehensive logging for debugging

## Security Considerations

- **Network**: Control only works over wired connection (per Savant notes)
- **Encryption**: AES128 encryption available but not required
- **Access**: Commands sent via local files (not network exposed)
- **Authentication**: Uses TV-generated keycode for encryption

## Future Enhancements

Potential improvements based on Savant profile:

1. **Full AES128 Encryption**: Implement proper encryption using keycode
2. **Additional Commands**: Add more Savant profile commands
3. **State Synchronization**: Better state sync with TV
4. **Error Recovery**: Enhanced error handling and recovery
5. **Performance**: Optimize connection management

---

*Based on Savant Blueprint profile analysis and LG C5 (2025) specifications*


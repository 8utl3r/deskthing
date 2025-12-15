# Hammerspoon Configuration Documentation

## Overview

This is a modular, well-structured Hammerspoon configuration with centralized configuration management, structured logging, and runtime debugging capabilities integrated with Cursor IDE.

## Quick Start

### Reload Configuration
- **Method 1 (Easiest)**: Press `Hyper+R` (Caps Lock + R)
- **Method 2**: Click Hammerspoon menu bar icon → "Reload Config"
- **Method 3**: Quit and restart Hammerspoon app

### Check for Errors
1. Click the **Hammerspoon icon** in your menu bar
2. Click **"Console"**
3. Look for error messages (red text)
4. Check log files in `~/.hammerspoon/logs/`

### Test Your Shortcuts
- **Hyper Key** = Caps Lock (when held)
- **Hyper+R** = Reload config
- **Hyper+T** = Launch WezTerm
- **Hyper+C** = Launch Cursor
- **Hyper+B** = Launch Mullvad Browser
- **Hyper+F** = Launch Finder
- **Hyper+N** = Move window to next screen
- **Hyper+Space** = Center window (70%)
- **Hyper+S** = Screenshot (area selection)

### Shortcut Overlay
- Hold **Command (⌘)** key for 0.3 seconds
- A window appears showing all available shortcuts
- Release Command to hide it
- Detects left vs right Command key for side-specific display

### Hammerflow Leader Key
- Press **F18** (recommend remapping Right Command to F18 in Karabiner)
- Follow with a key sequence to trigger actions
- See `hammerflow.toml` for configured shortcuts
- Examples: `F18+t` = WezTerm, `F18+c` = Cursor, `F18+h c` = Open Hammerspoon config in VS Code

**Note**: When using the leader key, you may see "hotkey: Disabled/Re-enabled previous hotkey ESCAPE" messages in the console. This is normal behavior - RecursiveBinder temporarily disables hotkeys to capture the leader key sequence. These messages come from the C-level hotkey extension and cannot be suppressed from Lua. To reduce console clutter, minimize the console window or ignore these informational messages.

## Architecture

### Directory Structure

```
hammerspoon/
├── init.lua                    # Main entry point (minimal)
├── config.lua                  # Centralized configuration
├── hammerflow.toml             # Hammerflow leader key configuration
├── lib/
│   ├── logger.lua              # Structured logging wrapper
│   ├── debug.lua                # Debugging infrastructure
│   └── utils.lua                # Shared utilities
├── modules/
│   ├── window-management.lua   # Window management
│   ├── app-launcher.lua        # App launchers
│   ├── caffeine.lua            # Sleep prevention
│   ├── shortcut-overlay.lua    # Shortcut overlay
│   ├── lg-monitor.lua          # LG monitor control
│   └── home-assistant.lua      # Home Assistant integration
├── Spoons/
│   └── Hammerflow.spoon/       # Leader key system
├── examples/                   # Example/test scripts
└── docs/
    └── README.md               # This file
```

### Module Pattern

All modules follow a consistent pattern:
- Return a table with public API
- `init()` function for initialization
- `cleanup()` function for resource cleanup
- Use structured logging via `lib.logger`
- Use centralized config via `config.lua`
- Register cleanup handlers with `hs.cleanup`

## Configuration

All configuration is centralized in `config.lua`. Key configuration areas:

- **Hyper key**: Modifier combination (default: cmd+alt+ctrl+shift)
- **App launchers**: Key mappings for applications
- **Window management**: Window sizing and positioning
- **Shortcut overlay**: Modifier, delay, and display settings
- **LG Monitor**: Server script paths, IP addresses
- **Home Assistant**: Server URL, token file, TV entities
- **Logging**: Log levels and directories
- **Debug**: Debug mode and trace file settings

### Environment Variables

- `HAMMERSPOON_DEBUG=true` - Enable debug mode (development)

## Logging

### Structured Logging

All modules use structured logging via `lib/logger.lua`:
- Log levels: debug, info, warning, error
- File-based logging to `~/.hammerspoon/logs/[module-name].log`
- Console output for development
- Timestamps and module names in all log entries

### Viewing Logs

```lua
-- In Hammerspoon Console
local logger = require("lib.logger")
local log = logger.get("module-name")
log:setLogLevel("debug")  -- Change log level
```

Or view log files directly:
```bash
tail -f ~/.hammerspoon/logs/hammerspoon.log
```

## Debugging

> **Quick Start**: See [DEBUGGING_QUICK_START.md](DEBUGGING_QUICK_START.md) for a 5-minute setup guide.  
> **DAP Adapter**: See [DAP_ADAPTER.md](DAP_ADAPTER.md) for full Cursor IDE integration with visual breakpoints, call stack, and variable inspection.  
> **Full Guide**: See [DEBUGGING.md](DEBUGGING.md) for complete documentation.

### DAP (Debug Adapter Protocol) Integration

The Hammerspoon setup includes a **full DAP adapter** that integrates with Cursor IDE's debug UI:

- ✅ **Visual Breakpoints** - Set breakpoints directly in the editor
- ✅ **Call Stack** - Navigate execution stack visually
- ✅ **Variable Inspection** - View local, module, and global variables
- ✅ **Step Controls** - Step over, into, and out of functions
- ✅ **Evaluate Expressions** - Evaluate Lua in debug console

**Quick Start**:
1. `export HAMMERSPOON_DEBUG=true`
2. In Cursor: `Cmd+Shift+D` → "Hammerspoon: Debug (DAP)" → `F5`
3. Set breakpoints by clicking in the gutter
4. Enable tracing: `debug.trace("module", "function")` in Hammerspoon Console
5. Reload and debug!

See [DAP_ADAPTER.md](DAP_ADAPTER.md) for complete documentation.

### Runtime Tracing with Cursor IDE

The configuration includes a comprehensive debugging framework (`lib/debug.lua`) that provides:

- Function call tracing with entry/exit logging
- Breakpoint support with pause/resume
- Variable state inspection
- Performance timing
- Full Cursor IDE integration via debug adapter

### Quick Start Debugging

1. **Enable Debug Mode**:
   ```bash
   export HAMMERSPOON_DEBUG=true
   ```

2. **Start Debug Adapter in Cursor**:
   - Open Run and Debug panel (Cmd+Shift+D)
   - Select "Hammerspoon: Debug"
   - Press F5

3. **Set Breakpoints**:
   ```bash
   # Using the management utility
   node hammerspoon/lib/debug-adapter/manage-breakpoints.js add shortcut-overlay showOverlay 0
   
   # Or edit ~/.hammerspoon/debug/breakpoints.json directly
   ```

4. **Enable Tracing** (in Hammerspoon Console):
   ```lua
   local debug = require("lib.debug")
   debug.trace("shortcut-overlay", "showOverlay")
   ```

5. **Reload Hammerspoon**: Press `Hyper+R`

See [DEBUGGING.md](DEBUGGING.md) for complete debugging guide.

### Debug Output

Debug traces are written to `~/.hammerspoon/debug/trace.json` in JSON format:

```json
{
  "timestamp": 1234567890,
  "timestampISO": "2025-01-06T12:00:00Z",
  "event": "call_start",
  "module": "shortcut-overlay",
  "function": "showOverlay",
  "data": {...},
  "callStackDepth": 2,
  "paused": false
}
```

### Debug Commands

```lua
-- In Hammerspoon Console
local debug = require("lib.debug")

-- Enable tracing for a specific function
debug.trace("shortcut-overlay", "showOverlay")

-- Set a breakpoint
debug.setBreakpoint("shortcut-overlay", "showOverlay", 0)

-- Export current state
debug.exportState("module-name", {state = "data"})

-- Time a function call
debug.time("module", "function", function()
    -- your code here
end)
```

## Modules

### Window Management

Provides window manipulation hotkeys:
- `Hyper+N`: Move window to next screen
- `Hyper+Space`: Center window at 70% size
- `Hyper+S`: Screenshot (area selection)

### App Launcher

Quick application launchers:
- `Hyper+T`: WezTerm
- `Hyper+C`: Cursor
- `Hyper+B`: Mullvad Browser
- `Hyper+F`: Finder

### Caffeine

Prevents system sleep with menu bar indicator:
- Click menu bar icon to toggle
- Shows "AWAKE" or "SLEEP" status

### Shortcut Overlay

FOSS alternative to CheatSheet:
- Hold Command key to show shortcuts
- Context-aware (shows shortcuts for current modifier combination)
- Apple glass design with transparency
- Side-specific display (left/right Command key)

### LG Monitor

Controls LG C5 monitor via server script:
- Menu bar status display
- Power, volume, input control
- Hotkeys for quick control
- Requires `bin/lg-server` script

### Home Assistant

Controls LG TVs via Home Assistant API:
- Dock detection for automatic volume adjustment
- TV power, volume, input control
- Hotkeys: `Cmd+Alt+T` (toggle), `Cmd+Alt+1/2/3/5` (volume), etc.
- Requires token file at `~/.homeassistant_token`

### Hammerflow

Leader key system for efficient keyboard-driven workflows:
- Press F18 (or configured leader key) to start sequences
- Nested key groups for organized shortcuts
- App launchers, window management, and custom actions
- Configuration in `hammerflow.toml`
- Auto-reloads when config files change
- Visual UI shows available key maps

**📚 Documentation:**
- **[Command Tree Logic & Explanation](hammerflow-command-tree.md)** - Detailed explanation of how the command tree works, parsing logic, and design principles
- **[Command Tree Diagram](hammerflow-command-tree-diagram.md)** - Visual diagrams, navigation flow, and quick reference card

## Troubleshooting

### "Nothing works!"
1. Check if Hammerspoon is running (menu bar icon)
2. Check Console for errors (menu bar icon → Console)
3. Check log files in `~/.hammerspoon/logs/`
4. Reload config: Press `Hyper+R`

### "Shortcut overlay doesn't show"
1. Check Console for errors about `shortcut-overlay`
2. Check log file: `~/.hammerspoon/logs/shortcut-overlay.log`
3. Verify modifier detection: Hold Command and check logs
4. Try enabling debug mode to see detailed traces

### "Home Assistant doesn't work"
1. Verify token file exists: `~/.homeassistant_token`
2. Check Home Assistant server is accessible
3. Check log file: `~/.hammerspoon/logs/home-assistant.log`
4. Test connection in Console:
   ```lua
   local ha = require("modules.home-assistant")
   ha.init()
   ```

### "LG Monitor doesn't work"
1. Verify server script exists: Check `config.lua` for path
2. Check log file: `~/.hammerspoon/logs/lg-monitor.log`
3. Verify monitor IP is correct in `config.lua`
4. Test server script manually: `bin/lg-server 192.168.0.39`

### Module Not Loading
1. Check Console for specific error messages
2. Check log file for the module
3. Verify module file exists in `modules/` directory
4. Check for syntax errors in module file

## Development

### Adding a New Module

1. Create `modules/my-module.lua`:
   ```lua
   local myModule = {}
   local logger = require("lib.logger").get("my-module")
   local config = require("config")
   local debug = require("lib.debug")
   
   function myModule.init()
       logger.info("Initializing my module")
       -- initialization code
       
       -- Register cleanup
       hs.cleanup = hs.cleanup or {}
       table.insert(hs.cleanup, myModule.cleanup)
   end
   
   function myModule.cleanup()
       logger.debug("Cleaning up my module")
       -- cleanup code
   end
   
   return myModule
   ```

2. Add to `init.lua` modules list:
   ```lua
   local modules = {
       -- ... existing modules
       "modules.my-module",
   }
   ```

3. Add configuration to `config.lua` if needed

### Testing

1. Reload config: `Hyper+R`
2. Check Console for errors
3. Check log files
4. Enable debug mode for detailed traces
5. Test functionality

## Resources

### Official Documentation
- **Main Documentation**: https://www.hammerspoon.org/docs/
- **API Index**: https://www.hammerspoon.org/docs/index.html
- **Getting Started**: https://www.hammerspoon.org/go/

### Community
- **GitHub**: https://github.com/Hammerspoon/hammerspoon
- **Discord**: https://discord.gg/hammerspoon
- **Google Group**: https://groups.google.com/forum/#!forum/hammerspoon
- **Awesome Hammerspoon**: https://github.com/ashfinal/awesome-hammerspoon

### Key Modules
- `hs.webview` - HTML/CSS/JS windows
- `hs.hotkey` - Hotkey bindings
- `hs.window` - Window management
- `hs.application` - Application control
- `hs.timer` - Timed events
- `hs.http` - HTTP requests

## Best Practices

1. **Use structured logging**: Always use `lib.logger`, never `print()`
2. **Centralize configuration**: All config in `config.lua`
3. **Clean up resources**: Always implement `cleanup()` function
4. **Error handling**: Use `pcall()` for risky operations
5. **Module pattern**: Follow the standard module structure
6. **Path resolution**: Use `utils.resolvePath()` for file paths

## File Locations

- **Configuration**: `/Users/pete/dotfiles/hammerspoon/`
- **Symlink target**: `~/.hammerspoon/` (should symlink to dotfiles)
- **Logs**: `~/.hammerspoon/logs/`
- **Debug traces**: `~/.hammerspoon/debug/`

## Support

For issues or questions:
1. Check log files first
2. Enable debug mode for detailed traces
3. Check Console for error messages
4. Review this documentation
5. Check Hammerspoon official resources

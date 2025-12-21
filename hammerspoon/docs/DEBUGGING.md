# Hammerspoon Debugging with Cursor IDE

## Overview

This guide explains how to debug Hammerspoon configurations using Cursor IDE's debug mode. The debugging system uses file-based communication between Hammerspoon and Cursor, providing breakpoints, variable inspection, and call stack tracking.

## Quick Start

### 1. Enable Debug Mode

```bash
export HAMMERSPOON_DEBUG=true
```

Or set it permanently in your shell profile:
```bash
echo 'export HAMMERSPOON_DEBUG=true' >> ~/.zshrc
```

### 2. Start Debug Adapter

In Cursor IDE:
1. Open the Run and Debug panel (Cmd+Shift+D)
2. Select "Hammerspoon: Debug" from the dropdown
3. Press F5 or click the green play button

This starts the debug adapter that monitors Hammerspoon's debug output.

### 3. Reload Hammerspoon

Press `Hyper+R` (Caps Lock + R) to reload your Hammerspoon configuration with debug mode enabled.

## Setting Breakpoints

### Method 1: Using Breakpoint File

Edit `~/.hammerspoon/debug/breakpoints.json`:

```json
{
  "breakpoints": [
    {
      "module": "shortcut-overlay",
      "function": "showOverlay",
      "line": 0,
      "enabled": true,
      "condition": null
    },
    {
      "module": "home-assistant",
      "function": "toggleTV",
      "line": 0,
      "enabled": true
    }
  ]
}
```

The debug adapter will automatically reload breakpoints when the file changes.

### Method 2: Programmatic Breakpoints

In Hammerspoon Console or your code:

```lua
local debug = require("lib.debug")

-- Set a breakpoint
debug.setBreakpoint("shortcut-overlay", "showOverlay", 0)

-- Clear a breakpoint
debug.clearBreakpoint("shortcut-overlay", "showOverlay")
```

## Debugging Workflow

### 1. Enable Function Tracing

In Hammerspoon Console:

```lua
local debug = require("lib.debug")

-- Enable tracing for a specific function
debug.trace("shortcut-overlay", "showOverlay")

-- Enable tracing for all functions in a module
debug.trace("home-assistant", "toggleTV")
debug.trace("home-assistant", "setTVVolume")
```

### 2. Trigger the Function

Use your Hammerspoon hotkeys or interact with the system to trigger the function you're debugging.

### 3. View Debug Output

The debug adapter will show:
- Function call start/end events
- Breakpoint hits
- Variable changes
- Errors
- Performance timing

### 4. Inspect State

When paused at a breakpoint, the current state is automatically exported to:
- `~/.hammerspoon/debug/current_state.json` - Full debug state
- `~/.hammerspoon/debug/state_<module>.json` - Module-specific state

### 5. Control Execution

Send commands to Hammerspoon by writing to `~/.hammerspoon/debug/commands.json`:

```json
{
  "command": "continue"
}
```

Available commands:
- `continue` - Resume execution after breakpoint
- `step` - Step over current line
- `getState` - Get current debug state

## Debug Files

All debug files are located in `~/.hammerspoon/debug/`:

- **`trace.json`** - Complete execution trace (JSON array)
- **`breakpoints.json`** - Active breakpoints
- **`commands.json`** - Commands from Cursor to Hammerspoon
- **`command_response.json`** - Responses from Hammerspoon
- **`current_state.json`** - Current debug state (updated on breakpoints/errors)
- **`state_<module>.json`** - Module-specific state exports

## Debug Events

The trace file contains events with the following structure:

```json
{
  "timestamp": 1234567890,
  "timestampISO": "2025-01-06T12:00:00Z",
  "event": "call_start",
  "module": "shortcut-overlay",
  "function": "showOverlay",
  "data": {
    "args": {...},
    "line": 0,
    "callStack": [...]
  },
  "callStackDepth": 2,
  "paused": false
}
```

Event types:
- `call_start` - Function called
- `call_end` - Function returned
- `breakpoint` - Breakpoint hit
- `variable_set` - Variable changed
- `error` - Error occurred
- `log` - Debug log message
- `performance` - Performance timing

## Advanced Usage

### Conditional Breakpoints

Set breakpoints with conditions in the breakpoint file:

```json
{
  "breakpoints": [
    {
      "module": "shortcut-overlay",
      "function": "showOverlay",
      "condition": "args.modifier == 'cmd'"
    }
  ]
}
```

Note: Conditional breakpoints require implementation in the debug system.

### Module State Export

Modules can export their state for inspection:

```lua
local debug = require("lib.debug")

-- Export module state
debug.exportState("my-module", {
    someVariable = value,
    anotherVariable = otherValue
})
```

### Performance Profiling

Time function execution:

```lua
local debug = require("lib.debug")

local result, duration = debug.time("my-module", "myFunction", function()
    -- code to profile
    return someValue
end)

print("Function took " .. duration .. " seconds")
```

## Integration with Cursor

### File Watching

Cursor can watch the debug files for changes:
- Open `~/.hammerspoon/debug/trace.json` in Cursor
- Use Cursor's file watcher to see real-time updates
- The debug adapter also monitors and displays events

### Debug Console

Use Cursor's integrated terminal to:
- Send commands to Hammerspoon
- View debug output
- Inspect state files

### Breakpoint Management

You can create a Cursor task or script to manage breakpoints:

```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Add Breakpoint",
      "type": "shell",
      "command": "node",
      "args": ["${workspaceFolder}/hammerspoon/lib/debug-adapter/manage-breakpoints.js", "add", "${input:module}", "${input:function}"]
    }
  ]
}
```

## Troubleshooting

### Debug adapter not starting

1. Check Node.js is installed: `node --version`
2. Check file permissions on debug directory
3. Verify `HAMMERSPOON_DEBUG=true` is set

### Breakpoints not working

1. Verify breakpoint file syntax is valid JSON
2. Check that module and function names match exactly
3. Ensure debug mode is enabled (`HAMMERSPOON_DEBUG=true`)
4. Reload Hammerspoon config after adding breakpoints

### No trace output

1. Verify debug mode is enabled
2. Check that functions are being traced: `debug.trace("module", "function")`
3. Check file permissions on debug directory
4. Look for errors in Hammerspoon Console

### State not updating

1. Check that `debug.exportCurrentState()` is being called
2. Verify state file permissions
3. Check for JSON encoding errors in Hammerspoon Console

## Best Practices

1. **Enable tracing selectively** - Don't trace everything, focus on the function you're debugging
2. **Use breakpoints strategically** - Set breakpoints at key decision points
3. **Export state on errors** - Always export state when errors occur
4. **Clear trace file** - The trace file grows over time, clear it periodically
5. **Use module-specific state** - Export state per module for better organization

## Example Debug Session

```lua
-- In Hammerspoon Console

-- 1. Enable debug mode (if not already enabled)
os.execute("export HAMMERSPOON_DEBUG=true")

-- 2. Enable tracing for the function you want to debug
local debug = require("lib.debug")
debug.trace("shortcut-overlay", "showOverlay")

-- 3. Set a breakpoint
debug.setBreakpoint("shortcut-overlay", "showOverlay", 0)

-- 4. Trigger the function (hold Command key)
-- Execution will pause at the breakpoint

-- 5. Inspect state
local state = debug.getCurrentState()
print(hs.inspect(state))

-- 6. Continue execution
-- Write {"command": "continue"} to ~/.hammerspoon/debug/commands.json
```

## Integration with Cursor Debug Mode

Cursor's debug mode can be enhanced with:
- Custom debug adapter configurations
- File watchers for real-time updates
- Custom tasks for breakpoint management
- Integration with Cursor's AI features for debugging assistance

See `.vscode/launch.json` for debug adapter configuration.




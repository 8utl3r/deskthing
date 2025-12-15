# Hammerspoon-Cursor Debug Integration Summary

## What We Built

A complete debugging system that integrates Hammerspoon with Cursor IDE's debug mode, providing:

1. **File-based Debug Adapter** - Node.js script that bridges Hammerspoon and Cursor
2. **Enhanced Debug Library** - Breakpoint support, state inspection, call stack tracking
3. **Breakpoint Management** - CLI tools for managing breakpoints
4. **Cursor Integration** - Launch configurations and tasks for seamless debugging

## Architecture

```
┌─────────────┐         ┌──────────────────┐         ┌──────────────┐
│  Cursor IDE │◄───────►│  Debug Adapter   │◄───────►│  Hammerspoon │
│  (DAP)      │         │  (Node.js)       │         │  (Lua)       │
└─────────────┘         └──────────────────┘         └──────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Debug Files     │
                    │  (JSON)          │
                    └──────────────────┘
```

### Communication Flow

1. **Breakpoints**: Cursor → `breakpoints.json` → Hammerspoon (watched)
2. **Commands**: Cursor → `commands.json` → Hammerspoon (watched)
3. **Traces**: Hammerspoon → `trace.json` → Debug Adapter → Cursor Console
4. **State**: Hammerspoon → `current_state.json` → Cursor (on breakpoints/errors)

## Components

### 1. Debug Adapter (`lib/debug-adapter/debug-adapter.js`)

- Monitors debug files for changes
- Displays trace events in Cursor's terminal
- Manages breakpoint file watching
- Handles command communication

**Usage**: Start via Cursor's Run and Debug panel

### 2. Enhanced Debug Library (`lib/debug.lua`)

**New Features**:
- Breakpoint support with pause/resume
- Automatic breakpoint file watching
- Command handling from Cursor
- State export on breakpoints/errors
- Timer cleanup on reload

**Key Functions**:
- `debug.setBreakpoint(module, function, line)` - Set breakpoint
- `debug.checkBreakpoint(module, function, line)` - Check if should break
- `debug.loadBreakpoints()` - Load from file
- `debug.watchBreakpoints()` - Watch for changes
- `debug.watchCommands()` - Watch for Cursor commands

### 3. Breakpoint Manager (`lib/debug-adapter/manage-breakpoints.js`)

CLI tool for managing breakpoints:
- `add` - Add breakpoint
- `remove` - Remove breakpoint
- `list` - List all breakpoints
- `clear` - Clear all breakpoints

### 4. Debug Helper (`lib/debug-helper.lua`)

Convenience utilities:
- `wrap()` - Auto-wrap function with tracing
- `autoTrace()` - Auto-trace all functions in module
- `traceFunction()` - Create traced version of function

### 5. Cursor Configuration

**`.vscode/launch.json`**:
- "Hammerspoon: Debug" - Start debug adapter
- "Hammerspoon: Attach" - Attach to running process (future)

**`.vscode/tasks.json`**:
- Breakpoint management tasks
- Trace file watching task

## Debug Workflow

### Setting Up a Debug Session

1. **Enable Debug Mode**:
   ```bash
   export HAMMERSPOON_DEBUG=true
   ```

2. **Start Debug Adapter** (Cursor):
   - Run and Debug panel → "Hammerspoon: Debug" → F5

3. **Set Breakpoint**:
   ```bash
   node hammerspoon/lib/debug-adapter/manage-breakpoints.js add shortcut-overlay showOverlay 0
   ```

4. **Enable Tracing** (Hammerspoon Console):
   ```lua
   local debug = require("lib.debug")
   debug.trace("shortcut-overlay", "showOverlay")
   ```

5. **Reload Hammerspoon**: `Hyper+R`

6. **Trigger Function**: Use hotkey or interact with system

7. **Debug**: Function pauses at breakpoint, state exported, inspect in Cursor

### During Debug Session

- **View Trace**: Debug adapter shows events in Cursor terminal
- **Inspect State**: Check `~/.hammerspoon/debug/current_state.json`
- **Continue**: Write `{"command":"continue"}` to `commands.json`
- **Step**: Write `{"command":"step"}` to `commands.json`

## File Structure

```
~/.hammerspoon/debug/
├── trace.json              # Execution trace (JSON array)
├── breakpoints.json        # Active breakpoints
├── commands.json           # Commands from Cursor
├── command_response.json   # Responses to Cursor
├── current_state.json      # Current debug state
└── state_<module>.json    # Module-specific states
```

## Integration Points

### Cursor IDE

1. **Debug Panel**: Start debug adapter via launch configuration
2. **Terminal**: View debug adapter output
3. **File Watcher**: Monitor trace.json for real-time updates
4. **Tasks**: Manage breakpoints via tasks
5. **AI Features**: Can analyze trace files and state

### Hammerspoon

1. **Console**: Enable tracing, set breakpoints programmatically
2. **Modules**: Use `debug.callStart/End` for tracing
3. **Breakpoints**: Automatically checked on function entry
4. **State Export**: Automatic on breakpoints and errors

## Benefits

1. **No Native DAP Required**: Works without Lua DAP adapter
2. **File-Based**: Simple, reliable communication
3. **Real-Time**: Fast feedback loop
4. **Integrated**: Works with Cursor's existing debug UI
5. **Extensible**: Easy to add new features

## Future Enhancements

1. **Conditional Breakpoints**: Evaluate conditions before breaking
2. **Variable Inspection**: Direct variable access from Cursor
3. **Step Over/Into**: More granular execution control
4. **Watch Expressions**: Monitor variable values
5. **Call Stack Navigation**: Navigate call stack in Cursor
6. **Performance Profiling**: Built-in performance analysis

## Limitations

1. **No True DAP**: Not a full DAP implementation, file-based instead
2. **Breakpoint Granularity**: Function-level, not line-level (Lua limitation)
3. **Pause Mechanism**: Uses polling loop, not true pause
4. **State Inspection**: Manual export required per module

## Usage Examples

### Example 1: Debug Shortcut Overlay

```bash
# 1. Set breakpoint
node hammerspoon/lib/debug-adapter/manage-breakpoints.js add shortcut-overlay showOverlay 0

# 2. Start debug adapter in Cursor (F5)

# 3. In Hammerspoon Console
local debug = require("lib.debug")
debug.trace("shortcut-overlay", "showOverlay")

# 4. Reload and trigger
# Hold Command key → breaks at showOverlay
```

### Example 2: Debug Home Assistant TV Control

```bash
# Set breakpoint
node hammerspoon/lib/debug-adapter/manage-breakpoints.js add home-assistant toggleTV 0

# Enable tracing
# In Console: debug.trace("home-assistant", "toggleTV")

# Trigger: Cmd+Alt+T
# Inspect: ~/.hammerspoon/debug/current_state.json
```

### Example 3: Performance Profiling

```lua
local debug = require("lib.debug")

local result, duration = debug.time("my-module", "slowFunction", function()
    -- code to profile
    return expensiveOperation()
end)

print("Function took " .. duration .. " seconds")
```

## Troubleshooting

See [DEBUGGING.md](DEBUGGING.md) for detailed troubleshooting guide.


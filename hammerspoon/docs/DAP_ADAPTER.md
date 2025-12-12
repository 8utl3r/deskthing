# Hammerspoon DAP Adapter

## Overview

The Hammerspoon DAP (Debug Adapter Protocol) adapter provides full integration with Cursor IDE's debug UI, including:

- **Visual Breakpoints** - Set breakpoints directly in the editor
- **Call Stack** - Navigate the execution stack
- **Variable Inspection** - View local, module, and global variables
- **Step Controls** - Step over, into, and out of functions
- **Evaluate Expressions** - Evaluate Lua expressions in the debug console

## Architecture

The DAP adapter (`dap-server.js`) implements the Debug Adapter Protocol and communicates with Hammerspoon via file-based messaging:

```
Cursor IDE ←→ DAP Server ←→ Debug Files ←→ Hammerspoon
```

## Quick Start

### 1. Install Dependencies

```bash
cd hammerspoon/lib/debug-adapter
npm install
```

### 2. Enable Debug Mode

```bash
export HAMMERSPOON_DEBUG=true
```

### 3. Start Debugging in Cursor

1. Open Run and Debug panel (`Cmd+Shift+D`)
2. Select "Hammerspoon: Debug (DAP)"
3. Press `F5`

### 4. Set Breakpoints

Click in the gutter next to any line in your Hammerspoon module files to set a breakpoint. The breakpoint will be automatically synchronized with Hammerspoon.

### 5. Enable Tracing

In Hammerspoon Console:

```lua
local debug = require("lib.debug")
debug.trace("shortcut-overlay", "showOverlay")
```

### 6. Reload and Debug

Press `Hyper+R` to reload Hammerspoon, then trigger your function. Execution will pause at breakpoints, and you can inspect variables in Cursor's debug panel.

## Features

### Breakpoints

- **Visual Breakpoints**: Click in the gutter to set/remove breakpoints
- **Conditional Breakpoints**: Right-click breakpoint → Edit Breakpoint → Add condition
- **Function Breakpoints**: Set breakpoints on function entry (Lua limitation: function-level only)

### Call Stack

The call stack shows:
- Module name
- Function name
- Source file location
- Line number (when available)

### Variables

Three scopes are available:
1. **Local** - Function arguments and local variables
2. **Module State** - Module-specific state exports
3. **Global** - Global Hammerspoon state

### Step Controls

- **Continue (F5)** - Resume execution
- **Step Over (F10)** - Execute current line, don't step into functions
- **Step Into (F11)** - Step into function calls
- **Step Out (Shift+F11)** - Step out of current function

### Evaluate

Use the Debug Console to evaluate Lua expressions:
- Hover over variables to see values
- Type expressions in the debug console
- Evaluate complex expressions

## How It Works

### Breakpoint Synchronization

1. User sets breakpoint in Cursor editor
2. DAP server receives `setBreakpointsRequest`
3. Breakpoint written to `~/.hammerspoon/debug/breakpoints.json`
4. Hammerspoon watches file and loads breakpoints
5. Execution pauses when breakpoint is hit

### State Synchronization

1. Hammerspoon exports state to `current_state.json`
2. DAP server watches file for changes
3. State loaded and displayed in Variables panel
4. Call stack built from state information

### Command Execution

1. User clicks Continue/Step in Cursor
2. DAP server sends command to `commands.json`
3. Hammerspoon watches file and executes command
4. Execution resumes or steps

## File Structure

```
~/.hammerspoon/debug/
├── breakpoints.json      # Breakpoints (managed by DAP server)
├── commands.json         # Commands from DAP server
├── command_response.json # Responses to DAP server
├── current_state.json    # Current debug state
└── trace.json            # Execution trace
```

## Configuration

### Launch Configuration

The DAP adapter is configured in `.vscode/launch.json`:

```json
{
  "name": "Hammerspoon: Debug (DAP)",
  "type": "node",
  "request": "launch",
  "program": "${workspaceFolder}/hammerspoon/lib/debug-adapter/dap-server.js",
  "console": "internalConsole",
  "env": {
    "HAMMERSPOON_DEBUG": "true",
    "HAMMERSPOON_DEBUG_DIR": "${env:HOME}/.hammerspoon/debug",
    "HAMMERSPOON_CONFIG_DIR": "${env:HOME}/.hammerspoon"
  }
}
```

### Environment Variables

- `HAMMERSPOON_DEBUG` - Enable debug mode (set to "true")
- `HAMMERSPOON_DEBUG_DIR` - Debug files directory (default: `~/.hammerspoon/debug`)
- `HAMMERSPOON_CONFIG_DIR` - Hammerspoon config directory (default: `~/.hammerspoon`)

## Limitations

### Lua-Specific Limitations

1. **Function-Level Breakpoints**: Lua doesn't support line-level breakpoints, so breakpoints are set at function entry
2. **Limited Source Mapping**: Source file paths are inferred from module names
3. **Variable Inspection**: Requires explicit state export from modules

### DAP Implementation

1. **File-Based Communication**: Uses file watching instead of direct IPC
2. **Polling**: State updates are polled (500ms interval)
3. **No Hot Reload**: Breakpoint changes require Hammerspoon reload

## Troubleshooting

### DAP Server Won't Start

1. Check Node.js: `node --version` (requires Node 14+)
2. Install dependencies: `cd hammerspoon/lib/debug-adapter && npm install`
3. Check file permissions on debug directory

### Breakpoints Not Working

1. Verify `HAMMERSPOON_DEBUG=true` is set
2. Check breakpoint file: `cat ~/.hammerspoon/debug/breakpoints.json`
3. Ensure module name matches file name
4. Reload Hammerspoon after setting breakpoints

### Variables Not Showing

1. Check state file: `cat ~/.hammerspoon/debug/current_state.json`
2. Verify modules export state: `debug.exportState("module", {...})`
3. Check that execution is paused at a breakpoint

### Call Stack Empty

1. Ensure tracing is enabled: `debug.trace("module", "function")`
2. Check trace file for call stack data
3. Verify state file contains call stack information

## Advanced Usage

### Custom Breakpoint Conditions

Right-click a breakpoint → Edit Breakpoint → Add condition:

```lua
args.modifier == "cmd"
```

Note: Conditional breakpoints require implementation in `debug.lua`.

### Module State Export

Export state for variable inspection:

```lua
local debug = require("lib.debug")

function myFunction()
    local state = {
        myVariable = value,
        anotherVar = otherValue
    }
    debug.exportState("my-module", state)
end
```

### Debug Helper

Use `debug-helper.lua` for automatic tracing:

```lua
local debugHelper = require("lib.debug-helper")

-- Auto-wrap function with tracing
local wrapped = debugHelper.wrap("my-module", "myFunction", originalFunction)

-- Auto-trace all functions in module
local module = debugHelper.autoTrace("my-module", {
    func1 = function() ... end,
    func2 = function() ... end
})
```

## Comparison: DAP vs Legacy

| Feature | DAP Adapter | Legacy Adapter |
|---------|-------------|----------------|
| Visual Breakpoints | ✅ | ❌ |
| Call Stack UI | ✅ | ❌ |
| Variable Inspection | ✅ | ❌ |
| Step Controls | ✅ | ❌ |
| Evaluate | ✅ | ❌ |
| File Watching | ✅ | ✅ |
| Trace Output | ✅ | ✅ |
| Breakpoint Management | ✅ | ✅ |

**Recommendation**: Use the DAP adapter for full IDE integration. Use the legacy adapter only if you need simple trace monitoring.

## Future Enhancements

1. **Direct IPC**: Replace file-based communication with direct IPC
2. **Hot Reload**: Support breakpoint changes without reload
3. **Line-Level Breakpoints**: If Lua debugger integration becomes available
4. **Watch Expressions**: Monitor variable values continuously
5. **Performance Profiling**: Built-in performance analysis UI

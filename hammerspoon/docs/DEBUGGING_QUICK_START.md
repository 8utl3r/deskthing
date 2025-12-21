# Quick Start: Debugging Hammerspoon in Cursor

## 5-Minute Setup

### Step 1: Enable Debug Mode

```bash
export HAMMERSPOON_DEBUG=true
```

### Step 2: Start Debug Adapter

1. Open Cursor IDE
2. Press `Cmd+Shift+D` (Run and Debug)
3. Select "Hammerspoon: Debug" from dropdown
4. Press `F5` or click the green play button

You should see:
```
🔍 Hammerspoon Debug Adapter started
📁 Debug directory: ~/.hammerspoon/debug
✅ Debug adapter ready. Waiting for Hammerspoon debug events...
```

### Step 3: Set a Breakpoint

```bash
node hammerspoon/lib/debug-adapter/manage-breakpoints.js add shortcut-overlay showOverlay 0
```

### Step 4: Enable Tracing

In Hammerspoon Console (menu bar → Console):

```lua
local debug = require("lib.debug")
debug.trace("shortcut-overlay", "showOverlay")
```

### Step 5: Reload and Test

1. Press `Hyper+R` to reload Hammerspoon
2. Trigger the function (hold Command key for shortcut overlay)
3. Watch the debug adapter output in Cursor's terminal

## Common Debugging Tasks

### View All Breakpoints

```bash
node hammerspoon/lib/debug-adapter/manage-breakpoints.js list
```

### Remove a Breakpoint

```bash
node hammerspoon/lib/debug-adapter/manage-breakpoints.js remove shortcut-overlay showOverlay
```

### Watch Trace File

In Cursor terminal:
```bash
tail -f ~/.hammerspoon/debug/trace.json
```

Or use the Cursor task: `Cmd+Shift+P` → "Tasks: Run Task" → "Hammerspoon: Watch Trace File"

## Debugging a Function

1. **Set breakpoint**: `manage-breakpoints.js add <module> <function> 0`
2. **Enable tracing**: `debug.trace("module", "function")` in Console
3. **Reload**: `Hyper+R`
4. **Trigger**: Use your hotkey or interact with system
5. **Inspect**: Check `~/.hammerspoon/debug/current_state.json`

## Troubleshooting

**Debug adapter won't start?**
- Check Node.js: `node --version`
- Check file permissions on `~/.hammerspoon/debug/`

**Breakpoints not working?**
- Verify `HAMMERSPOON_DEBUG=true` is set
- Check breakpoint file syntax: `cat ~/.hammerspoon/debug/breakpoints.json`
- Reload Hammerspoon after adding breakpoints

**No trace output?**
- Ensure tracing is enabled: `debug.trace("module", "function")`
- Check Hammerspoon Console for errors
- Verify debug mode is enabled

For detailed documentation, see [DEBUGGING.md](DEBUGGING.md).




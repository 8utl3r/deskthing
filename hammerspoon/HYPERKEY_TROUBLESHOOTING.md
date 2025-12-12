# Hyperkey Troubleshooting Guide

## Issue: Caps Lock stopped working as Hyper key

### Quick Fixes

1. **Restart Karabiner-Elements**
   - Open Karabiner-Elements app
   - Click "Quit Karabiner-Elements" in menu bar
   - Reopen Karabiner-Elements
   - Check if hyperkey works

2. **Check Karabiner-Elements Status**
   - Menu bar icon should show "Karabiner-Elements is running"
   - If red/disabled, click to enable
   - Check System Settings → Privacy & Security → Input Monitoring
     - Ensure Karabiner-Elements has permission

3. **Verify Configuration**
   - Open Karabiner-Elements → Complex Modifications
   - Ensure "Caps Lock: Hyper" rule is enabled (green toggle)
   - Check that profile "Default" is selected

4. **Test Karabiner Directly**
   - Open Karabiner-Elements → Event Viewer
   - Press Caps Lock
   - Should see: `left_shift` with modifiers `left_command, left_control, left_option`
   - If not, Karabiner isn't processing the key

### Potential Conflicts

**Hammerspoon EventTap Conflict**
- The shortcut-overlay uses `hs.eventtap` to detect Command keys
- This shouldn't interfere with Caps Lock, but to test:
  1. Temporarily disable shortcut-overlay in `init.lua`
  2. Reload Hammerspoon
  3. Test if hyperkey works
  4. If it works, the eventtap might be consuming events

**To Temporarily Disable Shortcut Overlay:**
```lua
-- Comment out this section in init.lua:
--[[
local success, err = pcall(function()
    require("shortcut-overlay")
end)
--]]
```

### System-Level Checks

1. **Check Input Monitoring Permissions**
   - System Settings → Privacy & Security → Input Monitoring
   - Both Karabiner-Elements AND Hammerspoon should be enabled
   - If not, enable and restart both apps

2. **Check Accessibility Permissions**
   - System Settings → Privacy & Security → Accessibility
   - Both apps should be enabled

3. **Restart Both Apps**
   ```bash
   # Kill both
   killall Karabiner-Elements
   killall Hammerspoon
   
   # Restart
   open -a Karabiner-Elements
   open -a Hammerspoon
   ```

### Debug Steps

1. **Check Hammerspoon Console**
   - Look for errors related to `eventtap`
   - Check if shortcut-overlay is logging key events

2. **Check Karabiner Logs**
   - Karabiner-Elements → Log → Show logs
   - Look for errors or blocked events

3. **Test Without Hammerspoon**
   - Quit Hammerspoon completely
   - Test if hyperkey works
   - If yes, Hammerspoon is interfering

### Fix EventTap Issue (if needed)

If the shortcut-overlay eventtap is the problem, we can modify it to:
- Only listen when Command is already pressed (not Caps Lock)
- Use a more specific event filter
- Return `false` to not consume events (already doing this)

### Quick Test Script

Run this in Hammerspoon console to test if eventtap is blocking:
```lua
-- Test if we can detect Caps Lock
local tap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    local keyCode = event:getKeyCode()
    print("Key pressed: " .. keyCode)
    if keyCode == 57 then  -- Caps Lock
        print("Caps Lock detected!")
    end
    return false  -- Don't consume
end)
tap:start()

-- Press Caps Lock and check console
-- Then stop: tap:stop()
```

### Expected Behavior

- **Caps Lock held**: Should send `cmd+opt+ctrl+shift` (hyper key)
- **Caps Lock tapped**: Should send `escape`
- **Caps Lock + other keys**: Should work as hyper key combo

If Caps Lock is just sending Caps Lock, Karabiner-Elements isn't processing it.








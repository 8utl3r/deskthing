# Testing Instructions - Shortcut Overlay

## Step 1: Reload Hammerspoon
Press `Hyper+R` (Caps Lock + R) to reload the configuration.

## Step 2: Open Hammerspoon Console
1. Click the **Hammerspoon icon** in your menu bar (top right)
2. Click **"Console"**

## Step 3: Run Diagnostic Tests
In the Console, type and press Enter:
```lua
require("test-overlay").runAll()
```

This will run a series of tests and show results. **Watch the console output** and note what passes/fails.

## Step 4: Test Debug Version
The debug version is already loaded. Now:

1. **Hold Command (⌘) key** for at least 1 second
2. **Watch the Console** - you should see detailed logs like:
   - `[TIME] OVERLAY DEBUG: EventTap callback #X fired`
   - `[TIME] OVERLAY DEBUG: Modifier pressed`
   - `[TIME] OVERLAY DEBUG: Timer fired`
   - etc.

3. **Report what you see**:
   - Do you see ANY logs when holding Command?
   - Do you see "EventTap callback" messages?
   - Do you see "Modifier pressed" messages?
   - Does the overlay window appear?

## Step 5: Manual Tests

### Test A: Check Modifier Detection
```lua
local flags = hs.eventtap.checkKeyboardModifiers()
print(hs.inspect(flags))
```
Hold Command key and run this - what does it show?

### Test B: Manual Overlay Show
```lua
require("shortcut-overlay-debug").show()
```
Does a window appear? If yes, window creation works. If no, that's the issue.

### Test C: Test EventTap Manually
```lua
local tap = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(e)
    print("Event:", hs.inspect(e:getFlags()))
    return false
end)
tap:start()
```
Now hold Command key - do you see "Event:" messages in console?

## What to Report Back

Please share:
1. Results from `require("test-overlay").runAll()` - which tests passed/failed?
2. When holding Command, do you see ANY console output from the debug version?
3. Does `require("shortcut-overlay-debug").show()` make a window appear?
4. What does `hs.eventtap.checkKeyboardModifiers()` show when Command is held?

This will help identify the actual root cause!

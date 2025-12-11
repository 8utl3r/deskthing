# Shortcut Overlay Fix Summary

## Problem
Shortcut overlay was not appearing when holding Command key.

## Root Cause
Two issues identified:
1. **EventTap unreliability**: EventTap-based detection can miss modifier-only events
2. **Overly strict detection**: Required modifier to be pressed ALONE (no other modifiers), but macOS sometimes reports additional modifiers

## Solution Implemented
Switched to **polling-based detection** using `hs.eventtap.checkKeyboardModifiers()`:
- More reliable (doesn't depend on eventtap events)
- More lenient (allows modifier even if others are pressed)
- Simpler code (easier to maintain)
- No Accessibility permission issues

## Files Created

1. **`shortcut-overlay-debug.lua`** - Debug version with comprehensive logging
2. **`shortcut-overlay-fixed.lua`** - Fixed version with logging (for testing)
3. **`shortcut-overlay.lua`** - Production version (clean, no debug logs)
4. **`test-overlay.lua`** - Diagnostic test script
5. **`DEBUG_LOG.md`** - Debugging findings and analysis

## How to Test

### Quick Test
1. **Reload Hammerspoon**: Press `Hyper+R` (Caps Lock + R)
2. **Hold Command key** for 0.5 seconds
3. **Overlay should appear** showing all shortcuts
4. **Release Command** - overlay should disappear

### If It Doesn't Work

1. **Check Console** (Hammerspoon menu bar → Console):
   - Look for any error messages
   - Check if module loaded successfully

2. **Run Diagnostics** (in Console):
   ```lua
   require("test-overlay").runAll()
   ```
   This will test all components and show what's working/not working.

3. **Test Manual Overlay** (in Console):
   ```lua
   require("shortcut-overlay").show()
   ```
   If this works, the issue is with modifier detection.

4. **Try Debug Version** (in Console):
   ```lua
   require("shortcut-overlay-debug")
   ```
   Then hold Command and watch the console for detailed logs.

## Key Changes

### Before (Original)
- Used `hs.eventtap` with `flagsChanged` events
- Required modifier to be pressed ALONE
- Complex state tracking with `lastFlags` table
- Relied on eventtap receiving all events

### After (Fixed)
- Uses `hs.eventtap.checkKeyboardModifiers()` polling every 50ms
- Allows modifier even if others are pressed
- Simple boolean state tracking (`lastModifierState`)
- More reliable detection

## Configuration

Edit `shortcut-overlay.lua` to customize:
- `config.modifier`: Change trigger key ("cmd", "alt", "ctrl", "shift")
- `config.delay`: Change delay before showing (default: 0.5 seconds)
- `shortcuts`: Add/modify shortcuts displayed

## Troubleshooting

### Overlay doesn't appear
1. Check Console for errors
2. Run diagnostic tests: `require("test-overlay").runAll()`
3. Try manual show: `require("shortcut-overlay").show()`
4. Check if `checkKeyboardModifiers()` works: `hs.eventtap.checkKeyboardModifiers()`

### Overlay appears but wrong shortcuts
- Edit the `shortcuts` table in `shortcut-overlay.lua`
- Reload Hammerspoon

### Overlay appears too quickly/slowly
- Adjust `config.delay` in `shortcut-overlay.lua`
- Reload Hammerspoon

## Status
✅ **Fixed and ready for testing**

The production version (`shortcut-overlay.lua`) is now active and should work reliably. If issues persist, use the debug version to gather more information.

# FOSS Desktop Management for macOS

## Summary

You now have a complete FOSS desktop/space management solution integrated into your Hammerspoon configuration. This provides power-user features for managing macOS Spaces/Desktops.

## What's Included

### 1. Desktop Management Module (`hammerspoon/modules/desktop-management.lua`)

A comprehensive Hammerspoon module that provides:
- ✅ **Space Renaming**: Custom names for desktops
- ✅ **App-to-Space Assignment**: Auto-move apps to specific spaces
- ✅ **App Restrictions**: Keep apps on assigned spaces
- ✅ **Quick Space Switching**: Fast navigation (Hyper + 1-9)

### 2. Documentation

- `hammerspoon/docs/DESKTOP_MANAGEMENT.md` - Full module documentation
- This guide - Quick reference

## Quick Start

### 1. Install Prerequisites

The module requires `hs.spaces`. Install it:

```bash
# In Hammerspoon console (Cmd+L), run:
hs.ipc.cliInstall('spaces')
```

Or manually: https://github.com/Hammerspoon/hammerspoon/tree/master/extensions/spaces

### 2. Configure App Assignments

Edit `hammerspoon/modules/desktop-management.lua` and customize:

```lua
local appSpaceAssignments = {
    ["Safari"] = {space = 2, restrict = true},
    ["Mail"] = {space = 3, restrict = false},
    ["Slack"] = {space = 4, restrict = true},
    ["Cursor"] = {space = 1, restrict = false},
}
```

### 3. Configure Space Names

```lua
local spaceNames = {
    [1] = "Main",
    [2] = "Work",
    [3] = "Communication",
    [4] = "Development",
}
```

### 4. Reload Configuration

Press `Hyper + R` (Cmd+Alt+Ctrl+Shift+R) to reload Hammerspoon.

## Hotkeys

| Hotkey | Action |
|--------|--------|
| `Hyper + 1-9` | Switch to space 1-9 |
| `Hyper + Shift + R` | Rename current space |

## Features

### Space Renaming

- Press `Hyper + Shift + R` to rename current space
- Names persist across sessions
- Custom names shown in notifications

### App Assignment

- Apps automatically move to assigned space on launch
- Optional restriction keeps apps on assigned space
- Works with any macOS application

### Space Switching

- Quick navigation with number keys
- Integrates with existing Hyper key setup
- Works alongside AeroSpace tiling window manager

## Integration with Existing Tools

### AeroSpace

The desktop management module works alongside AeroSpace:
- AeroSpace handles window tiling/layout
- Desktop management handles space-level organization
- Both can be used together seamlessly

### Hammerspoon

Fully integrated with your existing Hammerspoon setup:
- Uses your Hyper key configuration
- Follows your logging/debugging setup
- Respects your module loading system

## Alternative FOSS Tools

If you want additional features, consider:

### SpaceName Spoon
- More robust space renaming with menu bar display
- Install: `cd ~/.hammerspoon/Spoons && git clone https://github.com/ekalinin/SpaceName.spoon.git`

### restore-spaces Module
- Save and restore workspace layouts
- Useful for project-specific setups
- GitHub: https://github.com/tplobo/restore-spaces

## Limitations

1. **macOS Version**: Uses private APIs that may break with updates
2. **Space Detection**: Some limitations in detecting which space a window is on
3. **Restrictions**: Full enforcement may not be 100% reliable

## Troubleshooting

### Module not working?

1. Check if `hs.spaces` is installed: Run `hs.spaces.allSpaces()` in console
2. Verify Accessibility permissions in System Settings
3. Check Hammerspoon console for errors (Cmd+L)

### Apps not moving?

1. Verify app name matches exactly (case-sensitive)
2. Check console for errors
3. Try increasing delay in `handleAppLaunch` function

## Next Steps

1. **Customize**: Edit `appSpaceAssignments` and `spaceNames` in the module
2. **Test**: Launch apps and verify they move to assigned spaces
3. **Refine**: Adjust restrictions and assignments based on your workflow
4. **Extend**: Add Hammerflow bindings for easier access (see module docs)

## Files Modified/Created

- ✅ `hammerspoon/modules/desktop-management.lua` - New module
- ✅ `hammerspoon/init.lua` - Added module to loading list
- ✅ `hammerspoon/docs/DESKTOP_MANAGEMENT.md` - Full documentation
- ✅ `docs/DESKTOP_MANAGEMENT_GUIDE.md` - This guide

## References

- [Hammerspoon Spaces API](https://www.hammerspoon.org/docs/hs.spaces.html)
- [SpaceName Spoon](https://github.com/ekalinin/SpaceName)
- [Window Filter API](https://www.hammerspoon.org/docs/hs.window.filter.html)

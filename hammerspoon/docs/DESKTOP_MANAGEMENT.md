# Desktop/Space Management Module

## Overview

The `desktop-management` module provides FOSS desktop/space management capabilities for macOS using Hammerspoon. It integrates with your existing Hammerspoon configuration and provides:

- **Space Renaming**: Custom names for your desktops/spaces
- **App-to-Space Assignment**: Automatically move apps to specific spaces on launch
- **App Restrictions**: Keep apps restricted to their assigned spaces
- **Quick Space Switching**: Fast navigation between spaces

## Features

### 1. Space Renaming

Rename spaces with custom names that persist across sessions.

**Usage:**
- Press `Hyper + Shift + R` to rename the current space
- Enter a custom name in the dialog
- Space names are stored in the module configuration

**Example:**
```lua
-- In desktop-management.lua, customize spaceNames:
local spaceNames = {
    [1] = "Main",
    [2] = "Work",
    [3] = "Communication",
    [4] = "Development",
}
```

### 2. App-to-Space Assignment

Automatically move apps to specific spaces when they launch.

**Configuration:**
Edit `appSpaceAssignments` in `modules/desktop-management.lua`:

```lua
local appSpaceAssignments = {
    ["Safari"] = {space = 2, restrict = true},
    ["Mail"] = {space = 3, restrict = false},
    ["Slack"] = {space = 4, restrict = true},
    ["Cursor"] = {space = 1, restrict = false},
}
```

**Parameters:**
- `space`: Target space index (1-based) or space UUID
- `restrict`: If `true`, attempts to keep app windows on assigned space

### 3. Quick Space Switching

Switch between spaces using hotkeys.

**Hotkeys:**
- `Hyper + 1-9`: Switch to space 1-9

### 4. Programmatic API

Use the module programmatically in other scripts:

```lua
local dm = require("modules.desktop-management")

-- Switch to space 2
dm.switchToSpace(2)

-- Rename space 1
dm.setSpaceName(1, "Main Workspace")

-- Assign app to space
dm.setAppAssignment("Safari", 2, true)

-- Move app windows to space
dm.moveAppToSpace("Mail", 3)
```

## Installation & Setup

### Prerequisites

1. **Hammerspoon** must be installed and running
2. **hs.spaces module** - Install via:
   ```bash
   hs.ipc.cliInstall('spaces')
   ```
   Or manually install from: https://github.com/Hammerspoon/hammerspoon/tree/master/extensions/spaces

### Configuration

1. The module is automatically loaded via `init.lua`
2. Customize `appSpaceAssignments` and `spaceNames` in `modules/desktop-management.lua`
3. Reload Hammerspoon configuration: `Hyper + R`

## Limitations & Notes

### macOS Version Compatibility

- `hs.spaces` uses private APIs that may break with macOS updates
- Tested on macOS Sonoma (14.x) - compatibility varies by version
- Some features may require Accessibility permissions

### Space Detection

- Space detection relies on `hs.spaces` which uses private APIs
- Window-to-space detection has limitations - the module uses heuristics
- Full space restriction enforcement may not be 100% reliable

### Alternative: SpaceName Spoon

For more robust space renaming (with menu bar display), consider installing the **SpaceName** spoon:

```bash
# Install SpaceName spoon
cd ~/.hammerspoon/Spoons
git clone https://github.com/ekalinin/SpaceName.spoon.git
```

Then in your config:
```lua
hs.loadSpoon("SpaceName")
spoon.SpaceName:start()
```

## Integration with Hammerflow

Add desktop management commands to `hammerflow.toml`:

```toml
# Desktop management
[d]
label = "[desktop]"
1 = ["hs:local dm = require('modules.desktop-management'); dm.switchToSpace(1)", "Switch to Space 1"]
2 = ["hs:local dm = require('modules.desktop-management'); dm.switchToSpace(2)", "Switch to Space 2"]
r = ["hs:local dm = require('modules.desktop-management'); local cs = dm.getCurrentSpace(); local idx = dm.getSpaceIndex(cs); hs.dialog.textPrompt('Rename Space', 'Enter name:', '', 'OK', 'Cancel', function(r) if r then dm.setSpaceName(idx, r) end end)", "Rename Current Space"]
```

## Troubleshooting

### Module not loading

- Check Hammerspoon console for errors
- Verify `hs.spaces` is installed: `hs.spaces.allSpaces()`
- Ensure Accessibility permissions are granted

### Apps not moving to assigned spaces

- Verify app name matches exactly (case-sensitive)
- Check Hammerspoon console for errors
- Try increasing delay in `handleAppLaunch` (currently 0.5s)

### Space switching not working

- Verify `hs.spaces` module is functional
- Check macOS version compatibility
- Try manual space switching via Mission Control first

## Related Tools

- **AeroSpace**: Tiling window manager (already configured)
- **SpaceName Spoon**: Alternative space renaming solution
- **restore-spaces**: Workspace layout persistence module

## References

- [Hammerspoon Spaces API](https://www.hammerspoon.org/docs/hs.spaces.html)
- [SpaceName Spoon](https://github.com/ekalinin/SpaceName)
- [Window Filter API](https://www.hammerspoon.org/docs/hs.window.filter.html)

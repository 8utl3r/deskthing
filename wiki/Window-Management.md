# Window Management

This page covers window management, keyboard customization, and automation tools.

## AeroSpace Tiling Window Manager

**File**: `aerospace/aerospace.toml`  
**Linked to**: `~/.aerospace.toml`

### Configuration

```toml
# AeroSpace configuration
[general]
enable-normalization-flatten-containers = true

[keys]
alt-h = 'move-left'
alt-j = 'move-down'
alt-k = 'move-up'
alt-l = 'move-right'
alt-shift-h = 'resize-left'
alt-shift-j = 'resize-down'
alt-shift-k = 'resize-up'
alt-shift-l = 'resize-right'
alt-space = 'toggle-floating'
alt-semicolon = 'mode resize'
alt-shift-backslash = 'balance-sizes'
alt-q = 'close-window'
alt-shift-q = 'quit-aerospace'
alt-r = 'reload-config'
alt-shift-r = 'restart-aerospace'
alt-t = 'toggle-tiling'
alt-shift-t = 'toggle-tiling'
alt-w = 'focus-workspace'
alt-shift-w = 'move-window-to-workspace'
alt-1 = 'focus-workspace-1'
alt-2 = 'focus-workspace-2'
alt-3 = 'focus-workspace-3'
alt-4 = 'focus-workspace-4'
alt-5 = 'focus-workspace-5'
alt-6 = 'focus-workspace-6'
alt-7 = 'focus-workspace-7'
alt-8 = 'focus-workspace-8'
alt-9 = 'focus-workspace-9'
alt-shift-1 = 'move-window-to-workspace-1'
alt-shift-2 = 'move-window-to-workspace-2'
alt-shift-3 = 'move-window-to-workspace-3'
alt-shift-4 = 'move-window-to-workspace-4'
alt-shift-5 = 'move-window-to-workspace-5'
alt-shift-6 = 'move-window-to-workspace-6'
alt-shift-7 = 'move-window-to-workspace-7'
alt-shift-8 = 'move-window-to-workspace-8'
alt-shift-9 = 'move-window-to-workspace-9'

[gaps]
inner = 8
outer = 4
```

### Key Bindings

#### Window Movement
- `Alt + H/J/K/L`: Move focus between windows
- `Alt + Shift + H/J/K/L`: Resize windows
- `Alt + Space`: Toggle floating mode
- `Alt + Q`: Close window
- `Alt + Shift + Q`: Quit AeroSpace

#### Workspace Management
- `Alt + 1-9`: Switch to workspace
- `Alt + Shift + 1-9`: Move window to workspace
- `Alt + W`: Focus workspace (cycle)
- `Alt + Shift + W`: Move window to workspace

#### Layout Management
- `Alt + T`: Toggle tiling mode
- `Alt + Shift + T`: Toggle tiling mode
- `Alt + ;`: Enter resize mode
- `Alt + Shift + \`: Balance window sizes

#### System
- `Alt + R`: Reload configuration
- `Alt + Shift + R`: Restart AeroSpace

### Usage

```bash
# Install AeroSpace
brew install --cask nikitabobko/tap/aerospace

# Reload configuration
osascript -e 'tell application "AeroSpace" to quit' 2>/dev/null || true
open -a AeroSpace

# Or use the reload keybinding: Alt + R
```

### Features

- **i3-like Tiling**: Automatic window tiling
- **Gaps**: Configurable inner and outer gaps
- **Workspaces**: Multiple virtual desktops
- **Floating Windows**: Toggle floating mode
- **Resize Mode**: Precise window resizing
- **Configuration Reload**: Hot reload without restart

## Karabiner-Elements

**File**: `karabiner/karabiner.json`  
**Linked to**: `~/.config/karabiner/karabiner.json`

### Configuration

```json
{
  "global": {
    "check_for_updates_on_startup": true,
    "show_in_menu_bar": false,
    "show_profile_name_in_menu_bar": false
  },
  "profiles": [
    {
      "name": "Default",
      "selected": true,
      "simple_modifications": [],
      "complex_modifications": {
        "parameters": {
          "basic.to_if_alone_timeout_milliseconds": 250
        },
        "rules": [
          {
            "description": "Caps Lock: Hyper (cmd+opt+ctrl+shift) when held, Escape when tapped",
            "manipulators": [
              {
                "type": "basic",
                "from": { "key_code": "caps_lock", "modifiers": { "optional": ["any"] } },
                "to": [
                  { "key_code": "left_shift", "modifiers": ["left_command", "left_option", "left_control"] }
                ],
                "to_if_alone": [ { "key_code": "escape" } ]
              }
            ]
          }
        ]
      }
    }
  ]
}
```

### Hyper Key Setup

The Caps Lock key is transformed into a **Hyper Key**:

- **When held**: Becomes `Cmd + Opt + Ctrl + Shift`
- **When tapped**: Becomes `Escape`
- **Timeout**: 250ms to distinguish tap vs hold

### Usage

```bash
# Install Karabiner-Elements
brew install --cask karabiner-elements

# Launch and enable
open -a "Karabiner-Elements"

# The configuration is automatically loaded from dotfiles
```

### Hyper Key Benefits

- **Escape**: Quick access to Escape key
- **Modifier**: Four modifiers in one key
- **Hammerspoon Integration**: Works with automation scripts
- **No Conflicts**: Doesn't interfere with existing shortcuts

## Hammerspoon Automation

**File**: `hammerspoon/init.lua`  
**Linked to**: `~/.hammerspoon/init.lua`

### Configuration

```lua
local hyper = {"cmd", "alt", "ctrl", "shift"}

-- Reload config
hs.hotkey.bind(hyper, "r", function()
  hs.reload()
  hs.notify.new({title = "Hammerspoon", informativeText = "Config reloaded"}):send()
end)

-- Quick app launchers
local apps = {
  t = "WezTerm",
  c = "Cursor",
  b = "Mullvad Browser",
  f = "Finder",
}
for key, app in pairs(apps) do
  hs.hotkey.bind(hyper, key, function() hs.application.launchOrFocus(app) end)
end

-- Move window to next screen
hs.hotkey.bind(hyper, "n", function()
  local win = hs.window.focusedWindow()
  if win then win:moveToScreen(win:screen():next()) end
end)

-- Center window and size to 70%
hs.hotkey.bind(hyper, "space", function()
  local win = hs.window.focusedWindow()
  if not win then return end
  local screen = win:screen()
  local max = screen:frame()
  local w = max.w * 0.7
  local h = max.h * 0.7
  local x = max.x + (max.w - w) / 2
  local y = max.y + (max.h - h) / 2
  win:setFrame({x = x, y = y, w = w, h = h})
end)

-- Prevent sleep toggle (menubar)
local caffeine = hs.menubar.new()
local function setCaffeine(state)
  caffeine:setTitle(state and "AWAKE" or "SLEEP")
end
if caffeine then
  caffeine:setClickCallback(function()
    setCaffeine(hs.caffeinate.toggle("displayIdle"))
  end)
  setCaffeine(hs.caffeinate.get("displayIdle"))
end
```

### Key Bindings

All bindings use the **Hyper Key** (Caps Lock + modifier):

#### System
- `Hyper + R`: Reload Hammerspoon configuration
- `Hyper + Space`: Center and resize window to 70%

#### App Launchers
- `Hyper + T`: Launch/Focus WezTerm
- `Hyper + C`: Launch/Focus Cursor
- `Hyper + B`: Launch/Focus Mullvad Browser
- `Hyper + F`: Launch/Focus Finder

#### Window Management
- `Hyper + N`: Move window to next screen

#### Menubar
- **Caffeine Toggle**: Click menubar icon to prevent sleep

### Usage

```bash
# Install Hammerspoon
brew install --cask hammerspoon

# Launch and enable
open -a Hammerspoon

# Grant accessibility permissions when prompted
```

### Features

- **App Launchers**: Quick access to frequently used apps
- **Window Management**: Screen switching and centering
- **Sleep Prevention**: Toggle caffeine mode
- **Notifications**: Visual feedback for actions
- **Reload Support**: Hot reload configuration changes

## Alfred Application Launcher

**File**: `alfred/Alfred.alfredpreferences`  
**Linked to**: `~/Library/Application Support/Alfred/Alfred.alfredpreferences`

### Configuration

The Alfred preferences are managed through the linked directory, which includes:
- **Workflows**: Custom automation scripts
- **Themes**: Visual customization
- **Hotkeys**: Global shortcuts
- **Features**: File search, web search, etc.

### Usage

```bash
# Alfred is configured to sync with dotfiles
# The prefs.json points to: ~/dotfiles/alfred/Alfred.alfredpreferences

# Launch Alfred
# Default hotkey: Cmd + Space (same as Spotlight)
```

### Features

- **Application Launcher**: Quick app launching
- **File Search**: Find files and folders
- **Web Search**: Search engines integration
- **Workflows**: Custom automation
- **Clipboard History**: Access recent clipboard items
- **Calculator**: Quick calculations
- **System Commands**: Sleep, restart, etc.

## macOS System Defaults

**File**: `macos/defaults.sh`  
**Script**: Applies system-level tweaks

### Key Tweaks

#### Keyboard & Typing
- **Fast Key Repeat**: Minimal delay and fast repeat
- **Disable Auto-corrections**: Turn off automatic corrections
- **Full Keyboard Access**: Enable tab navigation

#### Trackpad
- **Tap to Click**: Enable tap-to-click
- **Natural Scrolling**: Enable natural scroll direction

#### Finder
- **Show All Files**: Show hidden files
- **Show Extensions**: Show file extensions
- **List View**: Default to list view
- **Path Bar**: Show full path
- **Status Bar**: Show status information
- **POSIX Paths**: Show full POSIX paths in title
- **No Animations**: Disable Finder animations

#### Dock
- **Auto-hide**: Hide dock automatically
- **No Recent Apps**: Don't show recent applications
- **No Hot Corners**: Disable hot corner actions
- **Fast Animation**: Quick hide/show animation

#### Screenshots
- **Custom Location**: Save to `~/Screenshots`
- **PNG Format**: Use PNG instead of TIFF
- **No Shadow**: Remove window shadows

### Usage

```bash
# Apply all defaults (dry-run by default)
./macos/defaults.sh

# Apply changes
./macos/defaults.sh --apply

# The script is idempotent and safe to run multiple times
```

## Troubleshooting

### Common Issues

1. **AeroSpace not responding**: Check if it's running, restart if needed
2. **Karabiner not working**: Grant accessibility permissions
3. **Hammerspoon not working**: Grant accessibility permissions
4. **Alfred not launching**: Check hotkey conflicts

### Debug Commands

```bash
# Check AeroSpace status
ps aux | grep aerospace

# Check Karabiner status
ps aux | grep karabiner

# Check Hammerspoon status
ps aux | grep hammerspoon

# Reload configurations
# AeroSpace: Alt + R
# Hammerspoon: Hyper + R
# Karabiner: Restart application
```

### Permissions

Ensure these applications have **Accessibility** permissions:
- Karabiner-Elements
- Hammerspoon
- AeroSpace

Grant permissions in: **System Preferences → Security & Privacy → Privacy → Accessibility**

# Hammerspoon Setup Guide

## Quick Start (For Dummies)

### 1. Reload Hammerspoon Configuration
**Method 1 (Easiest)**: Press `Hyper+R` (Caps Lock + R)
- This reloads your entire Hammerspoon config
- You'll see a notification when it's done

**Method 2**: Click Hammerspoon menu bar icon → "Reload Config"

**Method 3**: Quit and restart Hammerspoon app

### 2. Check for Errors
1. Click the **Hammerspoon icon** in your menu bar (top right)
2. Click **"Console"** 
3. Look for red error messages
4. If you see errors, they'll tell you what's broken

### 3. Test Your Shortcuts
- **Hyper Key** = Caps Lock (when held)
- **Hyper+R** = Reload config
- **Hyper+T** = Launch WezTerm
- **Hyper+C** = Launch Cursor
- **Hyper+B** = Launch Mullvad Browser
- **Hyper+F** = Launch Finder
- **Hyper+N** = Move window to next screen
- **Hyper+Space** = Center window (70%)

### 4. Test Shortcut Overlay
- Hold **Command (⌘)** key for 0.5 seconds
- A window should appear showing all your shortcuts
- Release Command to hide it

## Troubleshooting

### "Nothing works!"
1. **Check if Hammerspoon is running**: Look for the menu bar icon
2. **Check Console for errors**: Menu bar icon → Console
3. **Reload config**: Press `Hyper+R` or restart Hammerspoon

### "Shortcut overlay doesn't show"
1. Check Console for errors about `shortcut-overlay`
2. Try changing the modifier: Edit `shortcut-overlay.lua`, change `modifier = "cmd"` to `modifier = "alt"`
3. Reload config

### "Home Assistant doesn't work"
- This requires a token file - see `home-assistant/ha-tv-control.lua` for setup
- Errors will show in Console

### "LG Monitor doesn't work"
- This requires the LG server script to be accessible
- Check Console for path errors

## File Structure

```
~/.hammerspoon/
├── init.lua              # Main config (loads everything)
├── shortcut-overlay.lua  # Shortcut overlay (FOSS CheatSheet)
├── lg-c5/
│   └── lg-menu.lua      # LG Monitor control
└── home-assistant/
    └── ha-tv-control.lua # Home Assistant TV control
```

## What's Working

✅ **Basic shortcuts** (app launchers, window management)
✅ **Caffeine** (prevent sleep toggle in menu bar)
✅ **Shortcut overlay** (hold Command key)
✅ **LG Monitor control** (if server script exists)
⚠️ **Home Assistant** (requires token setup)

## Editing Config

1. Edit files in `/Users/pete/dotfiles/hammerspoon/`
2. Reload: Press `Hyper+R`
3. Check Console for errors

## Getting Help

- **Hammerspoon Console**: Shows all errors and can run Lua code
- **Check logs**: Console shows what's loading and any errors
- **Test in Console**: You can run Lua code directly to test things

# CheatSheet Configuration

**Note**: CheatSheet has been discontinued due to macOS 14 Sonoma incompatibility. A FOSS alternative is now available via Hammerspoon (see `hammerspoon/shortcut-overlay.lua`).

## FOSS Alternative: Hammerspoon Shortcut Overlay

A free and open-source shortcut overlay is now integrated into Hammerspoon. It shows all your custom keyboard shortcuts when holding a modifier key.

**Location**: `hammerspoon/shortcut-overlay.lua`  
**Usage**: Hold Command (⌘) key for 0.5 seconds to show shortcuts overlay

### Features
- Shows all Hyper key shortcuts (Caps Lock combinations)
- Shows all Command+Option shortcuts (Home Assistant TV control)
- Customizable modifier key and delay
- Modern, clean interface
- Fully integrated with your Hammerspoon configuration

### Configuration

Edit `hammerspoon/shortcut-overlay.lua` to customize:
- `config.modifier`: Which modifier key triggers the overlay ("cmd", "alt", "ctrl", "shift")
- `config.delay`: Delay before showing overlay (default: 0.5 seconds)
- `config.fontSize`: Font size for shortcuts
- Add or modify shortcuts in the `shortcuts` table

---

## Legacy CheatSheet Configuration (Deprecated)

This directory contains CheatSheet (shortcut viewer) configuration files that are symlinked to system locations.

### Files

- `com.mediaatelier.CheatSheet.plist` - Preferences file (symlinked to `~/Library/Preferences/com.mediaatelier.CheatSheet.plist`) - *Created after first use*

### Installation

CheatSheet is installed via Homebrew Cask (see `Brewfile`), but is no longer maintained and incompatible with macOS 14+.

### Configuration

CheatSheet was a simple utility that displayed keyboard shortcuts for the current application when you hold the Command (⌘) key.

After configuring CheatSheet (if preferences are created), run the symlink script to manage your settings in dotfiles:

```bash
scripts/system/link --apply
```

This will symlink:
- `~/Library/Preferences/com.mediaatelier.CheatSheet.plist` → `dotfiles/cheatsheet/com.mediaatelier.CheatSheet.plist`

### Bundle Identifier

- `com.mediaatelier.CheatSheet`

### Usage

Hold the Command (⌘) key in any application to view its keyboard shortcuts.





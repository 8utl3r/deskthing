# dotfiles

Reproducible, non-destructive macOS setup. Installs are manual by design.

## Status: ✅ Complete

All components installed, configured, and linked. Ready for development!

## Quick Start

```bash
# Link configuration files (dry-run by default)
./bin/link --apply

# Apply macOS system defaults (dry-run by default)  
./macos/defaults.sh --apply

# Install Homebrew packages manually
brew bundle --file ./Brewfile
```

## What's Included

### Shell & Terminal
- **Zsh** with aliases (`cat` → `bat`, `ls` → `eza`)
- **Starship** prompt with runtime detection
- **WezTerm** GPU-accelerated terminal
- **mise** runtime manager (Node.js, Python, Java, Rust)

### Development Tools
- **Git** with delta pager, aliases, and commit template
- **GitHub CLI** with vim editor and useful aliases
- **Docker** with CLI and Desktop configuration
- **CLI tools**: fzf, direnv, ripgrep, fd, bat, eza, jq, yq, httpie
- **Android tools**: ADB (Android Debug Bridge)

### Window Management & Automation
- **AeroSpace** tiling window manager
- **Karabiner-Elements** (Caps Lock → Hyper key)
- **Hammerspoon** Lua automation (app launchers, window management)

### Applications
- **Alfred 5** application launcher (⌘+Space)
- **Cursor** IDE with custom settings and keybindings
- **Docker** with CLI and Desktop configuration
- **CrossOver** Windows compatibility for running Windows games and apps
- **UTM** virtualization for Windows apps and games
- **Hidden Bar** menu bar management
- **IINA** media player
- **Itsycal** calendar widget
- **LM Studio** AI/ML development
- **Logi Options+** Logitech device management
- **Home Assistant** smart home automation
- **NetSpot** Wi-Fi analysis
- **PS Remote Play** PlayStation remote play
- **Raspberry Pi Imager** SD card imaging
- **Spotify** music streaming
- **Steam** gaming platform
- **Stremio** media streaming
- **Tailscale** VPN/network tool
- **Telegram** messaging
- **SlimHUD** volume/brightness HUD
- **Termius** SSH client

### System Configuration
- **macOS defaults** for power-user experience

## Configuration Files

### Scripts
- `bin/link`: symlink repo configs into `$HOME` (dry-run by default)
- `bin/bootstrap`: run symlinks; leaves installs to you
- `bin/cursor-extensions`: manage Cursor extensions
- `bin/snapshot`: update Brewfile and inventory
- `bin/hide-apple-apps`: hide/unhide Apple apps

### Core Configuration
- `Brewfile`: curated apps/tools (run with `brew bundle` manually)
- `runtimes/mise.toml`: runtime manager configuration
- `shell/.zshrc`: shell configuration with aliases
- `shell/starship.toml`: prompt configuration
- `git/.gitconfig`: Git settings and aliases
- `git/.gitignore_global`: global Git ignore rules
- `git/.gitmessage`: commit message template
- `gh/config.yml`: GitHub CLI configuration

### Application Configs
- `cursor/settings.json`: Cursor IDE settings
- `cursor/keybindings.json`: Cursor keybindings
- `cursor/snippets/`: Cursor user snippets
- `cursor/argv.json`: Cursor command-line arguments
- `cursor/locale.json`: Cursor locale settings
- `cursor/tasks.json`: Cursor task configuration
- `docker/config.json`: Docker CLI configuration
- `docker/daemon.json`: Docker daemon settings
- `docker/persisted-state.json`: Docker Desktop UI preferences
- `docker/window-management.json`: Docker Desktop window positions
- `aerospace/aerospace.toml`: tiling window manager config
- `karabiner/karabiner.json`: Karabiner-Elements config
- `hammerspoon/init.lua`: Hammerspoon automation
- `alfred/Alfred.alfredpreferences`: Alfred preferences
- `.editorconfig`: editor configuration

## Manual Setup Steps

Optional (AeroSpace):
```bash
# Install AeroSpace (from tap in Brewfile)
brew install --cask nikitabobko/tap/aerospace

# Reload AeroSpace after linking config
osascript -e 'tell application "AeroSpace" to quit' 2>/dev/null || true
open -a AeroSpace
```

Optional (Karabiner/Hammerspoon):
```bash
# Install
brew install --cask karabiner-elements hammerspoon

# After linking config
open -a "Karabiner-Elements"
open -a Hammerspoon
```

Optional (Alfred Sync):
```bash
# After linking, in Alfred Preferences → Advanced → Set preferences folder
# choose: ~/dotfiles/alfred/Alfred.alfredpreferences
# Note: license and caches are gitignored; do not commit your license.
```

Optional (Game Porting Toolkit):
```bash
# Using CrossOver instead - already purchased and installed
# CrossOver provides Windows compatibility for running Windows games
# More user-friendly than Game Porting Toolkit
```

Optional (iStatistica Pro):
```bash
# Download from App Store or Bjango website
# Install manually - not available via Homebrew
# Note: Already purchased, better than iStat Menus
```

Optional (Manual Installs):
```bash
# Xcode - Download from App Store (iOS/macOS development IDE) ✅ INSTALLED
# WiiM Home - Download from App Store or developer website (WiiM speaker control) ✅ INSTALLED
# XCloud - Download from Microsoft website (Xbox cloud gaming) ✅ INSTALLED
# TestFlight - Download from App Store (Apple's beta testing app) ✅ INSTALLED
# Pokit - Download from App Store (iOS version) ✅ INSTALLED
# Note: SlimHUD is deprecated and will be disabled on 2026-09-01
```

## Notes

- Git identity in `git/.gitconfig` is configured for pete/petersag3+commits@gmail.com
- Cursor settings live at `cursor/settings.json` and are linked by `bin/link`
- Keybindings live at `cursor/keybindings.json`
- Use `bin/cursor-extensions snapshot` to save current extensions
- Use `bin/cursor-extensions install` to install extensions from list
- macOS defaults include: Finder cleanliness, Dock hot corners off, screenshot folder and PNG, expanded save/print panels, local-save default, battery percent, natural scroll, prevent Photos auto-open. All are user-level and reversible by UI.
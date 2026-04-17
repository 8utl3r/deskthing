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
- **Hammerspoon** Lua automation (app launchers, window management, LG C5 monitor control)

### Applications
- **Alfred 5** application launcher (⌘+Space)
- **CheatSheet** shortcut viewer - shows keyboard shortcuts when holding Command (⌘) key
- **Cursor** IDE with custom settings and keybindings
- **Docker** with CLI and Desktop configuration
- **CrossOver** Windows compatibility for running Windows games and apps
- **UTM** virtualization for Windows apps and games
- **Ice** menu bar manager
- **IINA** media player
- **Itsycal** calendar widget
- **LM Studio** AI/ML development
- **Logi Options+** Logitech device management
- **Home Assistant** smart home automation with LG C5 monitor integration
- **NetSpot** Wi-Fi analysis
- **Proxyman** HTTP(S) debugging proxy
- **PS Remote Play** PlayStation remote play
- **Raspberry Pi Imager** SD card imaging
- **Spotify** music streaming
- **Steam** gaming platform
- **Stremio** media streaming
- **Tailscale** VPN/network tool
- **Telegram** messaging
- **SlimHUD** volume/brightness HUD
- **Termius** SSH client

### Home Assistant Integration
- **LG C5 Monitor Control** via webOS API (192.168.0.39)
- **macOS Integration** with dock status and sleep/wake detection
- **Automated Power Management** based on dock status
- **Volume and Input Control** with predefined scenes
- **macOS Notifications** for status updates
- **Configuration Files** managed via dotfiles symlinks
- **Remote Server** connection to Home Assistant at 192.168.0.105

### System Configuration
- **macOS defaults** for power-user experience

## Configuration Files

### Scripts
- `bin/link`: symlink repo configs into `$HOME` (dry-run by default)
- `bin/bootstrap`: run symlinks; leaves installs to you
- `bin/cursor-extensions`: manage Cursor extensions
- `bin/snapshot`: update Brewfile and inventory
- `bin/hide-apple-apps`: hide/unhide Apple apps
- `bin/ha-sync`: sync Home Assistant configs to remote server
- `bin/ha-validate`: validate Home Assistant YAML configurations
- `bin/ha-pull`: pull existing configuration from Home Assistant server (SSH)
- `bin/ha-pull-api`: pull configuration via Home Assistant API (basic)
- `bin/ha-pull-api-v2`: **RECOMMENDED** - comprehensive API-based configuration export
- `bin/ha-get-token`: helper to get your Home Assistant API token
- `bin/ha-export-guide`: guide for manually exporting configuration
- `bin/ha-analyze`: analyze exported configuration and compare with dotfiles

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
- `cursor/mcp.json`: Cursor MCP servers — [Cua setup](docs/services/cua-cursor-setup.md), [Qdrant setup](docs/services/qdrant-mcp-setup-complete.md)
- `docker/config.json`: Docker CLI configuration
- `docker/daemon.json`: Docker daemon settings
- `docker/persisted-state.json`: Docker Desktop UI preferences
- `docker/window-management.json`: Docker Desktop window positions
- `homeassistant/configuration.yaml`: Home Assistant main configuration
- `homeassistant/automations.yaml`: Home automation rules
- `homeassistant/scripts.yaml`: Reusable automation scripts
- `homeassistant/groups.yaml`: Device grouping and organization
- `homeassistant/scenes.yaml`: Predefined scenes for common configurations
- `homeassistant/secrets.yaml.template`: Template for sensitive configuration data
- `aerospace/aerospace.toml`: tiling window manager config
- `karabiner/karabiner.json`: Karabiner-Elements config
- `hammerspoon/init.lua`: Hammerspoon automation
- `alfred/Alfred.alfredpreferences`: Alfred preferences
- `proxyman/com.proxyman.NSProxy.plist`: Proxyman preferences
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

Optional (Home Assistant):
```bash
# Install Home Assistant Companion app
brew install --cask home-assistant

# Create secrets file from template
cp homeassistant/secrets.yaml.template ~/.homeassistant/secrets.yaml
# Edit ~/.homeassistant/secrets.yaml with your actual values

# After linking config, configure Home Assistant Companion
open -a "Home Assistant"
# Set server URL to: http://192.168.0.105:8123
```

**LG C5 Monitor Integration:**
- Enable "LG Connect Apps" in TV settings: `Settings > All Settings > Network > LG Connect Apps`
- Update MAC address in `~/.homeassistant/secrets.yaml`
- Configure LG webOS integration on Home Assistant server (192.168.0.105)
- Test webOS API integration through Home Assistant Companion app

**Home Assistant Development:**
```bash
# Get your API token (opens browser)
./bin/ha-get-token --open-browser

# Export your existing configuration via API
./bin/ha-pull-api-v2 --token YOUR_TOKEN

# Validate configurations before deploying
./bin/ha-validate --all

# Sync configurations to remote server
./bin/ha-sync --validate

# Dry run to see what would be synced
./bin/ha-sync --dry-run
```

See `homeassistant/DEVELOPMENT.md` for detailed development workflow.

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

- **Dotfiles Location**: `/Users/pete/dotfiles` (absolute path)
- Git identity in `git/.gitconfig` is configured for pete/petersag3+commits@gmail.com
- Cursor settings live at `cursor/settings.json` and are linked by `bin/link`
- Keybindings live at `cursor/keybindings.json`
- Use `bin/cursor-extensions snapshot` to save current extensions
- Use `bin/cursor-extensions install` to install extensions from list
- macOS defaults include: Finder cleanliness, Dock hot corners off, screenshot folder and PNG, expanded save/print panels, local-save default, battery percent, natural scroll, prevent Photos auto-open. All are user-level and reversible by UI.
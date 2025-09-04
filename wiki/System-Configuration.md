# System Configuration

This page covers macOS system defaults, system-level tweaks, and configuration management.

## macOS Defaults

**File**: `macos/defaults.sh`  
**Purpose**: Apply system-level tweaks for power-user experience

### Usage

```bash
# Dry-run (default) - shows what would be changed
./macos/defaults.sh

# Apply changes
./macos/defaults.sh --apply

# The script is idempotent and safe to run multiple times
```

### Configuration Categories

#### Keyboard & Typing
```bash
# Fast key repeat
defaults write -g KeyRepeat -int 1
defaults write -g InitialKeyRepeat -int 15

# Disable auto-corrections
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
defaults write -g NSAutomaticCapitalizationEnabled -bool false
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false

# Full keyboard access
defaults write -g AppleKeyboardUIMode -int 3
```

#### Trackpad
```bash
# Tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -int 1
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
```

#### Finder Enhancements
```bash
# Show all files and extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true

# Folder organization
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

# Search behavior
defaults write com.apple.finder FXDefaultSearchScope -string SCcf

# View preferences
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
defaults write com.apple.finder NewWindowTarget -string PfLo
defaults write com.apple.finder NewWindowTargetPath -string file://$HOME/

# Power-user features
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder DisableAllAnimations -bool true
defaults write com.apple.finder FXInfoPanesExpanded -dict General -bool true OpenWith -bool true Privileges -bool true

# Show Library folder
chflags nohidden "$HOME/Library"
```

#### Dock Configuration
```bash
# Auto-hide and appearance
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock tilesize -int 48

# Disable hot corners
defaults write com.apple.dock wvous-tl-corner -int 0
defaults write com.apple.dock wvous-tr-corner -int 0
defaults write com.apple.dock wvous-bl-corner -int 0
defaults write com.apple.dock wvous-br-corner -int 0

# Animation settings
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.12
defaults write com.apple.dock mineffect -string scale
defaults write com.apple.dock showhidden -bool true
```

#### Screenshots
```bash
# Custom location and format
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
defaults write com.apple.screencapture type -string png
defaults write com.apple.screencapture disable-shadow -bool true
```

#### Save/Print Panels
```bash
# Expanded panels by default
defaults write -g NSNavPanelExpandedStateForSaveMode -bool true
defaults write -g NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write -g PMPrintingExpandedStateForPrint -bool true
defaults write -g PMPrintingExpandedStateForPrint2 -bool true

# Default to local saves
defaults write -g NSDocumentSaveNewDocumentsToCloud -bool false
```

#### System UI
```bash
# Battery percentage
defaults write com.apple.controlcenter BatteryShowPercentage -bool true
defaults write com.apple.menuextra.battery ShowPercent -string YES

# Natural scrolling
defaults write -g com.apple.swipescrolldirection -bool true

# Scrollbars
defaults write -g AppleShowScrollBars -string WhenScrolling

# Menu bar clock with seconds
/usr/libexec/PlistBuddy -c "Set :MenuBarClock.ShowSeconds true" "$HOME/Library/Preferences/com.apple.menuextra.clock.plist" 2>/dev/null || true
```

#### Privacy & Telemetry
```bash
# Disable personalized ads
defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
defaults -currentHost write com.apple.AdLib allowApplePersonalizedAdvertising -bool false

# Disable analytics
defaults write com.apple.SubmitDiagInfo AutoSubmit -bool false
defaults write com.apple.applicationaccess AllowDiagnosticSubmission -bool false

# Disable crash dialogs
defaults write com.apple.CrashReporter DialogType -string none

# Disable Siri
defaults write com.apple.assistant.support "Assistant Enabled" -bool false
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.Siri UserHasDeclinedEnable -bool true
```

#### Device Behavior
```bash
# Prevent Photos from auto-opening
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

# Enable AirDrop over all interfaces
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true
```

### Service Restart

After applying changes, the script restarts affected services:

```bash
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true
```

## EditorConfig

**File**: `.editorconfig`  
**Linked to**: `~/.editorconfig`

### Configuration

```ini
root = true

[*]
end_of_line = lf
insert_final_newline = true
charset = utf-8
indent_style = space
indent_size = 2
trim_trailing_whitespace = true

[{Makefile,*.mk}]
indent_style = tab

[*.{py}]
indent_size = 4

[*.{md,txt}]
trim_trailing_whitespace = false
```

### Purpose

- **Consistent Coding Styles**: Enforces coding standards across editors
- **Cross-Editor Support**: Works with most modern editors
- **Project-Level**: Applies to entire project directories
- **Language-Specific**: Different rules for different file types

### Supported Editors

- Visual Studio Code / Cursor
- Sublime Text
- Atom
- IntelliJ IDEA
- Vim/Neovim
- Emacs
- And many more

## System Scripts

### Hide Apple Apps

**File**: `bin/hide-apple-apps`  
**Purpose**: Hide/unhide Apple applications and reset Dock

#### Usage

```bash
# Hide Apple apps
./bin/hide-apple-apps hide

# Unhide Apple apps
./bin/hide-apple-apps unhide

# Reset Dock to default
./bin/hide-apple-apps reset-dock
```

#### Features

- **Hide Apps**: Hide Apple applications from Applications folder
- **Unhide Apps**: Restore hidden Apple applications
- **Reset Dock**: Clear Dock and restore default state
- **Safe Operation**: Non-destructive operations

### Snapshot

**File**: `bin/snapshot`  
**Purpose**: Update Brewfile and inventory, then commit changes

#### Usage

```bash
# Update and commit
./bin/snapshot
```

#### Features

- **Brewfile Update**: Updates Brewfile with current packages
- **Inventory Update**: Updates package inventory files
- **Git Commit**: Commits changes with timestamp
- **State Tracking**: Maintains state files in `state/` directory

## Configuration Management

### Link Script

**File**: `bin/link`  
**Purpose**: Create symlinks from dotfiles to home directory

#### Usage

```bash
# Dry-run (default)
./bin/link

# Apply changes
./bin/link --apply
```

#### Features

- **Dry-Run by Default**: Safe operation mode
- **Backup Support**: Backs up existing files
- **Error Handling**: Graceful error handling
- **Comprehensive**: Links all configuration files

### Bootstrap Script

**File**: `bin/bootstrap`  
**Purpose**: Convenience wrapper to apply symlinks

#### Usage

```bash
# Apply all symlinks
./bin/bootstrap
```

## System Requirements

### macOS Version

- **Minimum**: macOS Sonoma 14.0
- **Recommended**: Latest macOS version
- **Architecture**: Apple Silicon (M1/M2/M3) or Intel

### Permissions Required

#### Accessibility
- Karabiner-Elements
- Hammerspoon
- AeroSpace

#### Full Disk Access
- Terminal applications
- Development tools

#### Screen Recording
- Screenshot tools
- Screen sharing applications

### Granting Permissions

1. **System Preferences** → **Security & Privacy** → **Privacy**
2. Select appropriate category (Accessibility, Full Disk Access, etc.)
3. Click the lock to make changes
4. Add applications as needed

## Troubleshooting

### Common Issues

#### Defaults Not Applying
```bash
# Check if script ran successfully
./macos/defaults.sh --apply

# Restart affected services manually
killall Dock
killall Finder
killall SystemUIServer
```

#### Permission Errors
```bash
# Check current permissions
ls -la ~/Library/Preferences/

# Reset permissions if needed
sudo chown -R $(whoami) ~/Library/Preferences/
```

#### Configuration Not Loading
```bash
# Check symlinks
ls -la ~/.config/
ls -la ~/Library/Application\ Support/

# Relink configurations
./bin/link --apply
```

### Debug Commands

```bash
# Check current defaults
defaults read com.apple.finder
defaults read com.apple.dock

# Check system information
system_profiler SPSoftwareDataType

# Check permissions
ls -la ~/Library/Preferences/
```

### Reverting Changes

Most defaults can be reverted by:

1. **System Preferences**: Use GUI to change settings
2. **Defaults Command**: Use `defaults delete` to remove custom settings
3. **Script Reversal**: Create reverse script for specific changes

### Safety Features

- **Dry-Run by Default**: Scripts show changes before applying
- **Backup Support**: Existing files are backed up before changes
- **Idempotent**: Scripts can be run multiple times safely
- **User-Level**: Most changes are user-level, not system-wide

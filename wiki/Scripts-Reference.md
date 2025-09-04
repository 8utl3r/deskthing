# Scripts Reference

This page provides detailed documentation for all automation scripts in the dotfiles.

## Core Scripts

### `bin/link`

**Purpose**: Create symlinks from dotfiles repository to home directory  
**Usage**: `./bin/link [--apply|--dry-run]`  
**Default**: Dry-run mode (safe by default)

#### Features
- **Dry-run by default**: Shows what would be changed without making changes
- **Backup support**: Backs up existing files before creating symlinks
- **Error handling**: Graceful handling of missing source files
- **Comprehensive**: Links all configuration files

#### Configuration Mappings
```bash
# Shell configuration
shell/.zshrc → ~/.zshrc
shell/starship.toml → ~/.config/starship.toml

# Git configuration
git/.gitconfig → ~/.gitconfig
git/.gitignore_global → ~/.gitignore_global
git/.gitmessage → ~/.gitmessage

# Runtime management
runtimes/mise.toml → ~/.config/mise/config.toml

# Terminal configuration
terminal/wezterm.lua → ~/.wezterm.lua

# Cursor IDE configuration
cursor/settings.json → ~/Library/Application Support/Cursor/User/settings.json
cursor/keybindings.json → ~/Library/Application Support/Cursor/User/keybindings.json
cursor/snippets → ~/Library/Application Support/Cursor/User/snippets
cursor/argv.json → ~/Library/Application Support/Cursor/argv.json
cursor/locale.json → ~/Library/Application Support/Cursor/User/locale.json
cursor/tasks.json → ~/Library/Application Support/Cursor/User/tasks.json

# Window management
aerospace/aerospace.toml → ~/.aerospace.toml
karabiner/karabiner.json → ~/.config/karabiner/karabiner.json
hammerspoon/init.lua → ~/.hammerspoon/init.lua

# Application configuration
gh/config.yml → ~/.config/gh/config.yml
alfred/Alfred.alfredpreferences → ~/Library/Application Support/Alfred/Alfred.alfredpreferences

# Docker configuration
docker/config.json → ~/.docker/config.json
docker/daemon.json → ~/.docker/daemon.json
docker/persisted-state.json → ~/Library/Application Support/Docker Desktop/persisted-state.json
docker/window-management.json → ~/Library/Application Support/Docker Desktop/window-management.json

# Editor configuration
.editorconfig → ~/.editorconfig
```

#### Usage Examples
```bash
# Dry-run (default)
./bin/link

# Apply changes
./bin/link --apply

# Check specific mappings
./bin/link --dry-run | grep "LINK:"
```

#### Backup Strategy
- Creates backup directory: `~/.dotfiles_backup_YYYYMMDD_HHMMSS`
- Moves existing files to backup before linking
- Only backs up non-symlink files

### `bin/bootstrap`

**Purpose**: Convenience wrapper to apply symlinks  
**Usage**: `./bin/bootstrap`

#### Features
- **Simple interface**: One command to apply all symlinks
- **Safe operation**: Uses the link script with apply flag
- **Error handling**: Exits on any errors

#### Usage
```bash
# Apply all symlinks
./bin/bootstrap
```

### `bin/snapshot`

**Purpose**: Update Brewfile and inventory, then commit changes  
**Usage**: `./bin/snapshot`

#### Features
- **Brewfile update**: Updates Brewfile with current packages
- **Inventory update**: Updates package inventory files
- **Git commit**: Commits changes with timestamp
- **State tracking**: Maintains state files in `state/` directory

#### Generated Files
- `state/brew-casks.txt`: Current Homebrew casks
- `state/brew-formulae.txt`: Current Homebrew formulae
- `state/brew-taps.txt`: Current Homebrew taps
- `state/apps-system.txt`: System applications
- `state/apps-user.txt`: User applications

#### Usage
```bash
# Update and commit
./bin/snapshot

# Check what was updated
git log --oneline -1
```

### `bin/cursor-extensions`

**Purpose**: Manage Cursor (VS Code-compatible) extensions  
**Usage**: `./bin/cursor-extensions [install|snapshot]`

#### Features
- **Extension management**: Install and snapshot extensions
- **CLI detection**: Automatically detects cursor or code CLI
- **Extension list**: Maintains `cursor/extensions.txt`

#### Commands
```bash
# Save current extensions
./bin/cursor-extensions snapshot

# Install extensions from list
./bin/cursor-extensions install
```

#### Generated Files
- `cursor/extensions.txt`: List of installed extensions

### `bin/hide-apple-apps`

**Purpose**: Hide/unhide Apple applications and reset Dock  
**Usage**: `./bin/hide-apple-apps [hide|unhide|reset-dock]`

#### Features
- **Hide Apple apps**: Hide Apple applications from Applications folder
- **Unhide Apple apps**: Restore hidden Apple applications
- **Reset Dock**: Clear Dock and restore default state
- **Safe operation**: Non-destructive operations

#### Commands
```bash
# Hide Apple applications
./bin/hide-apple-apps hide

# Unhide Apple applications
./bin/hide-apple-apps unhide

# Reset Dock to default
./bin/hide-apple-apps reset-dock
```

#### Affected Applications
- Calculator
- Calendar
- Chess
- Contacts
- DVD Player
- FaceTime
- Font Book
- Image Capture
- Keychain Access
- Mail
- Maps
- Messages
- Mission Control
- Notes
- Photo Booth
- QuickTime Player
- Reminders
- Stickies
- System Preferences
- TextEdit
- Time Machine
- Voice Memos

### `bin/update`

**Purpose**: Update script for maintaining dotfiles  
**Usage**: `./bin/update`

#### Features
- **Package updates**: Update Homebrew packages
- **Configuration sync**: Sync configurations
- **System maintenance**: Apply system defaults
- **Git operations**: Commit and push changes

#### Usage
```bash
# Run update
./bin/update
```

## System Scripts

### `macos/defaults.sh`

**Purpose**: Apply macOS system defaults for power-user experience  
**Usage**: `./macos/defaults.sh [--apply|--dry-run]`  
**Default**: Dry-run mode (safe by default)

#### Features
- **Idempotent**: Safe to run multiple times
- **Dry-run by default**: Shows changes before applying
- **Comprehensive**: Covers keyboard, trackpad, Finder, Dock, etc.
- **Service restart**: Restarts affected services after changes

#### Configuration Categories
- **Keyboard & Typing**: Fast repeat, disable auto-corrections
- **Trackpad**: Tap to click, natural scrolling
- **Finder**: Show all files, extensions, path bar, status bar
- **Dock**: Auto-hide, disable hot corners, fast animation
- **Screenshots**: Custom location, PNG format, no shadow
- **Save/Print Panels**: Expanded by default, local saves
- **System UI**: Battery percentage, natural scrolling, scrollbars
- **Privacy**: Disable personalized ads, analytics, Siri
- **Device Behavior**: Prevent Photos auto-open, enable AirDrop

#### Usage
```bash
# Dry-run (default)
./macos/defaults.sh

# Apply changes
./macos/defaults.sh --apply
```

#### Service Restart
After applying changes, restarts:
- Dock
- Finder
- SystemUIServer

## Script Architecture

### Error Handling
All scripts use `set -euo pipefail` for:
- **Exit on error**: `set -e`
- **Unset variables**: `set -u`
- **Pipe failures**: `set -o pipefail`

### Bash Compatibility
Scripts are compatible with Bash 3.x (macOS default):
- **No associative arrays**: Uses space-separated arrays
- **Portable syntax**: Avoids Bash 4+ features
- **Cross-platform**: Works on different Unix systems

### Safety Features
- **Dry-run by default**: Scripts show changes before applying
- **Backup support**: Existing files are backed up
- **Idempotent**: Scripts can be run multiple times safely
- **Error handling**: Graceful error handling and reporting

## Usage Patterns

### Initial Setup
```bash
# Clone repository
git clone https://github.com/8utl3r/petes-m3-setup.git ~/dotfiles
cd ~/dotfiles

# Apply configurations
./bin/link --apply
./macos/defaults.sh --apply

# Install packages
brew bundle --file ./Brewfile
```

### Regular Maintenance
```bash
# Update configurations
./bin/link --apply

# Update system defaults
./macos/defaults.sh --apply

# Update package inventory
./bin/snapshot
```

### Troubleshooting
```bash
# Check what would be changed
./bin/link --dry-run
./macos/defaults.sh --dry-run

# Verify current state
ls -la ~/.zshrc ~/.gitconfig ~/.config/

# Check script status
./bin/cursor-extensions snapshot
```

## Customization

### Adding New Configurations
1. **Add file to repository**: Place configuration file in appropriate directory
2. **Update link script**: Add mapping to `LINK_PAIRS` array
3. **Test dry-run**: `./bin/link --dry-run`
4. **Apply changes**: `./bin/link --apply`

### Modifying Scripts
1. **Edit script**: Modify script in `bin/` directory
2. **Test changes**: Run with dry-run flags
3. **Apply changes**: Run with apply flags
4. **Commit changes**: Use `./bin/snapshot`

### Adding New Defaults
1. **Edit defaults script**: Add new defaults to `macos/defaults.sh`
2. **Test dry-run**: `./macos/defaults.sh --dry-run`
3. **Apply changes**: `./macos/defaults.sh --apply`
4. **Test functionality**: Verify changes work as expected

## Best Practices

### Script Development
- **Use dry-run by default**: Always show changes before applying
- **Provide backups**: Backup existing files before changes
- **Handle errors gracefully**: Use proper error handling
- **Document usage**: Include usage examples and descriptions

### Maintenance
- **Regular updates**: Run scripts regularly to keep configurations current
- **Test changes**: Always test changes before applying
- **Backup before changes**: Create backups before major changes
- **Monitor logs**: Check logs for errors and issues

### Troubleshooting
- **Use dry-run first**: Always check what would be changed
- **Check permissions**: Ensure scripts have proper permissions
- **Verify dependencies**: Check that required tools are installed
- **Test incrementally**: Test changes one at a time

# Configuration Files

This page provides a complete reference for all configuration files managed by the dotfiles.

## File Structure

```
dotfiles/
├── bin/                    # Automation scripts
│   ├── bootstrap          # Apply symlinks
│   ├── cursor-extensions  # Manage Cursor extensions
│   ├── hide-apple-apps   # Hide/unhide Apple apps
│   ├── link              # Create symlinks
│   ├── snapshot          # Update and commit
│   └── update            # Update script
├── shell/                 # Shell configuration
│   ├── .zshrc            # Zsh configuration
│   └── starship.toml     # Starship prompt config
├── git/                   # Git configuration
│   ├── .gitconfig        # Git settings
│   ├── .gitignore_global # Global ignore rules
│   └── .gitmessage       # Commit template
├── cursor/                # Cursor IDE settings
│   ├── argv.json         # Command-line arguments
│   ├── keybindings.json  # Custom keybindings
│   ├── locale.json       # Language settings
│   ├── settings.json     # Editor preferences
│   ├── snippets/         # User snippets
│   └── tasks.json        # Task configurations
├── docker/                # Docker configuration
│   ├── config.json       # CLI configuration
│   ├── daemon.json       # Daemon settings
│   ├── persisted-state.json # UI preferences
│   └── window-management.json # Window positions
├── aerospace/             # Window manager
│   └── aerospace.toml    # Tiling configuration
├── karabiner/             # Keyboard customization
│   └── karabiner.json    # Key mappings
├── hammerspoon/           # Automation
│   └── init.lua          # Lua scripts
├── alfred/                # Application launcher
│   └── Alfred.alfredpreferences/ # Preferences
├── macos/                 # System defaults
│   └── defaults.sh       # macOS tweaks
├── runtimes/              # Runtime manager
│   └── mise.toml         # Runtime configuration
├── terminal/              # Terminal configuration
│   └── wezterm.lua       # WezTerm settings
├── gh/                    # GitHub CLI
│   └── config.yml        # CLI configuration
├── state/                 # State tracking
│   ├── apps-system.txt   # System applications
│   ├── apps-user.txt     # User applications
│   ├── brew-casks.txt    # Homebrew casks
│   ├── brew-formulae.txt # Homebrew formulae
│   └── brew-taps.txt     # Homebrew taps
├── .editorconfig          # Editor configuration
├── .gitignore            # Repository ignore rules
├── Brewfile              # Homebrew packages
└── README.md             # Project documentation
```

## Core Configuration Files

### Shell Configuration

#### `.zshrc`
**Location**: `shell/.zshrc` → `~/.zshrc`  
**Purpose**: Zsh shell configuration with aliases and environment setup

**Key Features**:
- Homebrew environment setup
- mise runtime manager initialization
- direnv environment loading
- Enhanced `cat` and `ls` commands
- fzf integration

#### `starship.toml`
**Location**: `shell/starship.toml` → `~/.config/starship.toml`  
**Purpose**: Cross-shell prompt configuration

**Key Features**:
- Directory display with repo truncation
- Git branch and status
- Runtime detection (Node.js, Python, Rust)
- Command duration display
- Fast performance (800ms timeout)

### Git Configuration

#### `.gitconfig`
**Location**: `git/.gitconfig` → `~/.gitconfig`  
**Purpose**: Global Git configuration

**Key Features**:
- User identity (pete/petersag3+commits@gmail.com)
- Delta pager for enhanced diffs
- Useful aliases (co, br, ci, st, hist)
- zdiff3 conflict style
- Commit template integration

#### `.gitignore_global`
**Location**: `git/.gitignore_global` → `~/.gitignore_global`  
**Purpose**: Global Git ignore patterns

**Patterns**:
- macOS system files (`.DS_Store`)
- Node.js (`node_modules/`, `dist/`)
- Python (`__pycache__/`, `*.pyc`, `.venv/`)
- Logs and temporary files
- Editor files (`.vscode/`, `.idea/`)

#### `.gitmessage`
**Location**: `git/.gitmessage` → `~/.gitmessage`  
**Purpose**: Git commit message template

**Format**: Conventional commits with type, scope, body, and footer

### Cursor IDE Configuration

#### `settings.json`
**Location**: `cursor/settings.json` → `~/Library/Application Support/Cursor/User/settings.json`  
**Purpose**: Editor preferences

**Key Settings**:
- Telemetry disabled
- Minimap disabled
- JetBrains Mono font with ligatures
- Custom title bar
- Terminal font consistency

#### `keybindings.json`
**Location**: `cursor/keybindings.json` → `~/Library/Application Support/Cursor/User/keybindings.json`  
**Purpose**: Custom keybindings

**Bindings**:
- `Ctrl+Cmd+T`: Toggle terminal
- `Ctrl+Cmd+B`: Toggle sidebar
- `Ctrl+Cmd+E`: Focus explorer

#### Additional Files
- `argv.json`: Command-line arguments
- `locale.json`: Language settings
- `tasks.json`: Task configurations
- `snippets/`: User code snippets

### Docker Configuration

#### `config.json`
**Location**: `docker/config.json` → `~/.docker/config.json`  
**Purpose**: Docker CLI configuration

**Settings**:
- Credential store: desktop
- Current context: desktop-linux

#### `daemon.json`
**Location**: `docker/daemon.json` → `~/.docker/daemon.json`  
**Purpose**: Docker daemon settings

**Settings**:
- Builder garbage collection enabled
- Default keep storage: 20GB

#### `persisted-state.json`
**Location**: `docker/persisted-state.json` → `~/Library/Application Support/Docker Desktop/persisted-state.json`  
**Purpose**: Docker Desktop UI preferences

#### `window-management.json`
**Location**: `docker/window-management.json` → `~/Library/Application Support/Docker Desktop/window-management.json`  
**Purpose**: Docker Desktop window positions

## Window Management

### AeroSpace Configuration

#### `aerospace.toml`
**Location**: `aerospace/aerospace.toml` → `~/.aerospace.toml`  
**Purpose**: Tiling window manager configuration

**Key Features**:
- Alt-based keybindings
- Window movement (H/J/K/L)
- Window resizing (Shift+H/J/K/L)
- Workspace management (1-9)
- Floating mode toggle
- Gaps configuration

### Karabiner Configuration

#### `karabiner.json`
**Location**: `karabiner/karabiner.json` → `~/.config/karabiner/karabiner.json`  
**Purpose**: Keyboard customization

**Key Features**:
- Caps Lock → Hyper key (Cmd+Opt+Ctrl+Shift)
- Caps Lock → Escape when tapped
- 250ms timeout for tap detection

### Hammerspoon Configuration

#### `init.lua`
**Location**: `hammerspoon/init.lua` → `~/.hammerspoon/init.lua`  
**Purpose**: Lua automation scripts

**Key Features**:
- Hyper key integration
- App launchers (T, C, B, F)
- Window management (N, Space)
- Caffeine toggle
- Configuration reload

## Application Configuration

### Alfred Configuration

#### `Alfred.alfredpreferences`
**Location**: `alfred/Alfred.alfredpreferences` → `~/Library/Application Support/Alfred/Alfred.alfredpreferences`  
**Purpose**: Application launcher preferences

**Contents**:
- Workflows directory
- Themes directory
- Preferences directory
- License and caches (gitignored)

### GitHub CLI Configuration

#### `config.yml`
**Location**: `gh/config.yml` → `~/.config/gh/config.yml`  
**Purpose**: GitHub CLI configuration

**Settings**:
- Git protocol: https
- Editor: vim
- Pager: delta
- Aliases: co, pv, pc, run

## System Configuration

### macOS Defaults

#### `defaults.sh`
**Location**: `macos/defaults.sh`  
**Purpose**: macOS system tweaks

**Categories**:
- Keyboard and typing
- Trackpad settings
- Finder enhancements
- Dock configuration
- Screenshot settings
- Privacy and telemetry
- UI improvements

### Runtime Configuration

#### `mise.toml`
**Location**: `runtimes/mise.toml` → `~/.config/mise/config.toml`  
**Purpose**: Runtime manager configuration

**Runtimes**:
- Node.js: lts
- Python: 3.12
- Java: temurin-21
- Rust: stable

### Terminal Configuration

#### `wezterm.lua`
**Location**: `terminal/wezterm.lua` → `~/.wezterm.lua`  
**Purpose**: WezTerm terminal configuration

**Settings**:
- Font: JetBrains Mono Nerd Font
- Font size: 13.0
- No tab bar
- Native decorations
- Fullscreen support

## Editor Configuration

### EditorConfig

#### `.editorconfig`
**Location**: `.editorconfig` → `~/.editorconfig`  
**Purpose**: Cross-editor configuration

**Rules**:
- Line endings: LF
- Charset: UTF-8
- Indent: 2 spaces
- Trim trailing whitespace
- Language-specific overrides

## Package Management

### Brewfile
**Location**: `Brewfile`  
**Purpose**: Homebrew package list

**Contents**:
- 28 formulae (CLI tools)
- 26 casks (GUI applications)
- 1 tap (AeroSpace)
- 1 VS Code extension

## State Tracking

### State Files
**Location**: `state/` directory  
**Purpose**: Track installed packages and system state

**Files**:
- `apps-system.txt`: System applications
- `apps-user.txt`: User applications
- `brew-casks.txt`: Homebrew casks
- `brew-formulae.txt`: Homebrew formulae
- `brew-taps.txt`: Homebrew taps

## Scripts

### Automation Scripts
**Location**: `bin/` directory  
**Purpose**: Automation and management

**Scripts**:
- `bootstrap`: Apply symlinks
- `cursor-extensions`: Manage Cursor extensions
- `hide-apple-apps`: Hide/unhide Apple apps
- `link`: Create symlinks
- `snapshot`: Update and commit
- `update`: Update script

## File Permissions

### Symlink Permissions
All configuration files are linked with appropriate permissions:
- Configuration files: 644
- Directories: 755
- Scripts: 755

### Backup Strategy
The `link` script creates backups before making changes:
- Backup directory: `~/.dotfiles_backup_YYYYMMDD_HHMMSS`
- Existing files are moved to backup before linking

## Maintenance

### Regular Updates
```bash
# Update all configurations
./bin/link --apply

# Update system defaults
./macos/defaults.sh --apply

# Update package inventory
./bin/snapshot
```

### Validation
```bash
# Check all symlinks
./bin/link --dry-run

# Verify configurations
ls -la ~/.zshrc ~/.gitconfig ~/.config/

# Check application support
ls -la ~/Library/Application\ Support/ | grep -E "(Alfred|Docker|Cursor)"
```

# Shell & Terminal

This page covers all shell and terminal-related components managed by the dotfiles.

## Zsh Configuration

**File**: `shell/.zshrc`  
**Linked to**: `~/.zshrc`

### Features

- **Smart Aliases**: Automatic fallbacks for enhanced commands
- **Homebrew Integration**: Automatic PATH setup
- **mise Integration**: Runtime manager initialization
- **direnv Integration**: Automatic environment loading
- **fzf Integration**: Fuzzy finding capabilities

### Key Aliases

```bash
# Enhanced commands with fallbacks
cat() {
  if command -v bat >/dev/null 2>&1; then
    bat --paging=never "$@"
  else
    command cat "$@"
  fi
}

ls() {
  if command -v eza >/dev/null 2>&1; then
    eza --group-directories-first --icons=auto "$@"
  else
    command ls "$@"
  fi
}

# Standard aliases
alias ll="ls -lah"
```

### Usage

The shell automatically:
- Loads Homebrew environment
- Initializes mise for runtime management
- Sets up direnv for project-specific environments
- Provides enhanced `cat` and `ls` commands

## Starship Prompt

**File**: `shell/starship.toml`  
**Linked to**: `~/.config/starship.toml`

### Configuration

```toml
add_newline = true
command_timeout = 800
format = "$directory$git_branch$git_status$nodejs$python$rust$cmd_duration$line_break$character"

[directory]
style = "bold blue"
truncate_to_repo = true
truncation_length = 3

[character]
success_symbol = "❯ "
error_symbol = "✖ "

[git_branch]
format = "on [$symbol$branch]($style) "
style = "purple"

[git_status]
format = "([$all_status$ahead_behind]($style) )"
style = "yellow"
```

### Features

- **Directory**: Shows current directory with repo truncation
- **Git Status**: Branch name and status indicators
- **Runtime Detection**: Shows Node.js, Python, Rust versions
- **Command Duration**: Shows time for long-running commands
- **Fast**: Optimized for speed with 800ms timeout

### Customization

Edit `shell/starship.toml` to modify:
- Colors and styles
- Module order and format
- Timeout settings
- Character symbols

## WezTerm Terminal

**File**: `terminal/wezterm.lua`  
**Linked to**: `~/.wezterm.lua`

### Configuration

```lua
local wezterm = require 'wezterm'

local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.font = wezterm.font_with_fallback({
  'JetBrainsMono Nerd Font',
  'Iosevka',
  'Menlo',
})
config.font_size = 13.0
config.enable_tab_bar = false
config.window_decorations = 'RESIZE'
config.use_fancy_tab_bar = false
config.native_macos_fullscreen_mode = true

return config
```

### Features

- **GPU Acceleration**: Hardware-accelerated rendering
- **Font Fallbacks**: JetBrains Mono → Iosevka → Menlo
- **Clean Interface**: No tab bar, native decorations
- **Fullscreen Support**: Native macOS fullscreen mode

### Usage

- **Launch**: `wezterm` or from Applications
- **Config Reload**: `Cmd+,` → Reload Config
- **Font Size**: `Cmd+Plus/Minus` to adjust
- **Fullscreen**: `Cmd+Ctrl+F`

## mise Runtime Manager

**File**: `runtimes/mise.toml`  
**Linked to**: `~/.config/mise/config.toml`

### Configuration

```toml
[tools]
node = "lts"           # Stable Node.js for broad compatibility
python = "3.12"        # Current stable Python
java = "temurin-21"    # LTS Java from Eclipse Temurin
rust = "stable"        # Stable Rust toolchain
```

### Usage

```bash
# Install all configured runtimes
mise install

# Install specific runtime
mise install node@18

# List installed versions
mise list

# Set global version
mise use node@lts

# Enable Corepack for pnpm
corepack enable pnpm
```

### Features

- **Automatic Version Management**: Switches versions based on project
- **Fast Installation**: Parallel downloads and builds
- **Project Support**: `.mise.toml` files for project-specific versions
- **Tool Support**: Node.js, Python, Java, Rust, and more

## CLI Tools

### Enhanced Commands

- **bat**: Enhanced `cat` with syntax highlighting
- **eza**: Modern `ls` replacement with icons and colors
- **fd**: Fast `find` alternative
- **ripgrep**: Fast `grep` alternative
- **fzf**: Fuzzy finder for command history and files
- **direnv**: Automatic environment loading
- **jq**: JSON processor
- **yq**: YAML/XML/CSV processor
- **httpie**: User-friendly HTTP client

### Usage Examples

```bash
# Find files
fd "*.js" src/

# Search in files
rg "function" --type js

# Fuzzy find files
fzf

# Process JSON
echo '{"name": "test"}' | jq '.name'

# Process YAML
yq eval '.key' file.yml

# HTTP requests
http GET https://api.github.com/user
```

## Environment Management

### direnv

Automatically loads environment variables from `.envrc` files:

```bash
# In project directory
echo "export API_KEY=secret" > .envrc
direnv allow

# Environment automatically loaded when entering directory
```

### Project-specific Runtimes

Create `.mise.toml` in project directories:

```toml
[tools]
node = "18.17.0"
python = "3.11"
```

## Troubleshooting

### Common Issues

1. **Font not found**: Install JetBrains Mono Nerd Font
2. **Slow prompt**: Check Starship timeout settings
3. **Runtime not found**: Run `mise install`
4. **Environment not loading**: Check `.envrc` permissions

### Debug Commands

```bash
# Check shell configuration
zsh -c "echo $PATH"

# Test Starship
starship prompt

# Check mise status
mise doctor

# Test direnv
direnv status
```

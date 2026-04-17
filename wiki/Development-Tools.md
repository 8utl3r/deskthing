# Development Tools

This page covers all development-related tools and configurations managed by the dotfiles.

## Git Configuration

**File**: `git/.gitconfig`  
**Linked to**: `~/.gitconfig`

### Features

- **Delta Pager**: Enhanced diff display with syntax highlighting
- **Useful Aliases**: Shortcuts for common Git operations
- **Conflict Style**: zdiff3 for better merge conflict resolution
- **Commit Template**: Conventional commit format
- **Global Ignores**: Common patterns to ignore

### Configuration

```ini
[user]
    name = pete
    email = petersag3+commits@gmail.com

[core]
    editor = vim
    excludesfile = ~/.gitignore_global
    commitTemplate = ~/.gitmessage

[diff]
    pager = delta

[merge]
    conflictStyle = zdiff3

[alias]
    co = checkout
    br = branch
    ci = commit
    st = status
    hist = log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short
    type = cat-file -t
    dump = cat-file -p
```

### Usage

```bash
# Common operations
git st                    # status
git co main              # checkout main
git br feature-branch    # create branch
git ci -m "feat: add feature"  # commit with template

# View history
git hist                 # formatted log

# Check file type
git type HEAD~1          # show object type
git dump HEAD~1          # show object content
```

### Global Git Ignore

**File**: `git/.gitignore_global`  
**Linked to**: `~/.gitignore_global`

Ignores common patterns:
- macOS system files (`.DS_Store`)
- Node.js (`node_modules/`, `dist/`)
- Python (`__pycache__/`, `*.pyc`, `.venv/`)
- Logs and temporary files
- Editor files (`.vscode/`, `.idea/`)

### Commit Template

**File**: `git/.gitmessage`  
**Linked to**: `~/.gitmessage`

Promotes conventional commits:

```
# <type>(scope): short summary
#
# Body: explain what and why (wrap at ~72 chars)
# - bullet points welcome
#
# Footer: references, BREAKING CHANGE, closes #123
#
# Types: feat, fix, chore, docs, style, refactor, perf, test, build, ci
```

## GitHub CLI

**File**: `gh/config.yml`  
**Linked to**: `~/.config/gh/config.yml`

### Configuration

```yaml
git_protocol: https
editor: vim
pager: delta
aliases:
    co: pr checkout
    pv: pr view -w
    pc: pr create --fill
    run: run view --log-failed
```

### Usage

```bash
# Authentication
gh auth login

# Pull requests
gh pr list                    # list PRs
gh pr checkout 123          # checkout PR #123
gh pr view -w               # view PR in browser
gh pr create --fill         # create PR with template

# Issues
gh issue list               # list issues
gh issue create             # create issue

# Repositories
gh repo clone owner/repo    # clone repository
gh repo create             # create new repository

# Workflows
gh run list                # list workflow runs
gh run view --log-failed   # view failed runs
```

### Aliases

- `gh co 123`: Checkout PR #123
- `gh pv`: View PR in browser
- `gh pc`: Create PR with template
- `gh run`: View failed workflow runs

## Docker Configuration

### CLI Configuration

**File**: `docker/config.json`  
**Linked to**: `~/.docker/config.json`

```json
{
    "auths": {},
    "credsStore": "desktop",
    "currentContext": "desktop-linux"
}
```

### Daemon Settings

**File**: `docker/daemon.json`  
**Linked to**: `~/.docker/daemon.json`

```json
{
  "builder": {
    "gc": {
      "defaultKeepStorage": "20GB",
      "enabled": true
    }
  },
  "experimental": false
}
```

### Desktop UI Preferences

**File**: `docker/persisted-state.json`  
**Linked to**: `~/Library/Application Support/Docker Desktop/persisted-state.json`

**File**: `docker/window-management.json`  
**Linked to**: `~/Library/Application Support/Docker Desktop/window-management.json`

### Usage

```bash
# Docker Desktop
# Launch from Applications or:
open -a Docker

# CLI operations
docker ps                   # list containers
docker images              # list images
docker build -t myapp .    # build image
docker run -p 3000:3000 myapp  # run container

# Docker Compose
docker-compose up          # start services
docker-compose down        # stop services
docker-compose logs        # view logs
```

## Cursor IDE

### Settings

**File**: `cursor/settings.json`  
**Linked to**: `~/Library/Application Support/Cursor/User/settings.json`

```json
{
  "telemetry.telemetryLevel": "off",
  "editor.minimap.enabled": false,
  "editor.renderWhitespace": "boundary",
  "editor.cursorSmoothCaretAnimation": true,
  "editor.cursorBlinking": "phase",
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.fontFamily": "JetBrains Mono, Menlo, Monaco, Courier New, monospace",
  "editor.fontLigatures": true,
  "window.titleBarStyle": "custom",
  "terminal.integrated.fontFamily": "JetBrainsMono Nerd Font",
  "workbench.startupEditor": "none"
}
```

### Keybindings

**File**: `cursor/keybindings.json`  
**Linked to**: `~/Library/Application Support/Cursor/User/keybindings.json`

```json
[
  { "key": "ctrl+cmd+t", "command": "workbench.action.terminal.toggleTerminal" },
  { "key": "ctrl+cmd+b", "command": "workbench.action.toggleSidebarVisibility" },
  { "key": "ctrl+cmd+e", "command": "workbench.view.explorer" }
]
```

### Additional Configuration

- **Snippets**: `cursor/snippets/` directory for custom snippets
- **Tasks**: `cursor/tasks.json` for task configurations
- **Locale**: `cursor/locale.json` for language settings
- **Arguments**: `cursor/argv.json` for command-line arguments
- **MCP servers**: `cursor/mcp.json` — [Cua (computer-use agent)](../docs/services/cua-cursor-setup.md), [Qdrant (vector search)](../docs/services/qdrant-mcp-setup-complete.md)

### Usage

```bash
# Launch Cursor
cursor .                   # open current directory
cursor file.js            # open specific file

# Extensions management
bin/cursor-extensions snapshot    # save current extensions
bin/cursor-extensions install     # install from saved list

# Key shortcuts
Ctrl+Cmd+T                # toggle terminal
Ctrl+Cmd+B                # toggle sidebar
Ctrl+Cmd+E                # focus explorer
```

## CLI Development Tools

### File Operations

- **bat**: Enhanced `cat` with syntax highlighting
- **eza**: Modern `ls` with icons and colors
- **fd**: Fast file finder
- **ripgrep**: Fast text search

### Data Processing

- **jq**: JSON processor
- **yq**: YAML/XML/CSV processor
- **httpie**: HTTP client
- **adb**: Android Debug Bridge

### Usage Examples

```bash
# File operations
bat file.js               # syntax-highlighted file viewing
eza -la                   # detailed listing with icons
fd "*.js" src/           # find JavaScript files
rg "function" --type js   # search for functions in JS files

# Data processing
echo '{"name": "test"}' | jq '.name'
yq eval '.key' file.yml
http GET https://api.github.com/user

# Fuzzy finding
fzf                       # interactive file finder
history | fzf             # search command history
```

## Android Debug Bridge (ADB)

**Installation**: `brew install android-platform-tools`  
**Purpose**: Android development and device management

### Features

- **Device Management**: Connect to Android devices
- **App Installation**: Install APK files
- **File Transfer**: Transfer files to/from devices
- **Debugging**: Debug Android applications
- **Shell Access**: Access device shell
- **Logcat**: View device logs

### Usage

```bash
# Check ADB version
adb --version

# List connected devices
adb devices

# Connect to device
adb connect <device-ip>

# Install APK
adb install app.apk

# Uninstall app
adb uninstall com.package.name

# Transfer files
adb push local-file /sdcard/remote-file
adb pull /sdcard/remote-file local-file

# Access device shell
adb shell

# View logs
adb logcat

# Clear logs
adb logcat -c

# Filter logs
adb logcat | grep "MyApp"

# Reboot device
adb reboot

# Enable USB debugging (on device)
# Settings → Developer Options → USB Debugging
```

### Common Commands

```bash
# Device management
adb devices                    # list devices
adb connect 192.168.1.100     # connect via WiFi
adb disconnect                # disconnect device

# App management
adb install app.apk           # install APK
adb uninstall com.package     # uninstall app
adb shell pm list packages    # list installed packages

# File operations
adb push file.txt /sdcard/    # upload file
adb pull /sdcard/file.txt .   # download file
adb shell ls /sdcard/         # list files

# Debugging
adb logcat                    # view logs
adb shell dumpsys activity    # dump activity info
adb shell getprop             # get system properties
```

### Setup Requirements

1. **Enable Developer Options** on Android device:
   - Settings → About Phone → Tap "Build Number" 7 times
   
2. **Enable USB Debugging**:
   - Settings → Developer Options → USB Debugging

3. **Connect Device**:
   - USB cable or WiFi ADB
   - Accept debugging prompt on device

### Troubleshooting

```bash
# Check if ADB server is running
adb start-server

# Kill ADB server
adb kill-server

# Restart ADB server
adb kill-server && adb start-server

# Check device authorization
adb devices -l

# Reset device authorization
adb kill-server
rm ~/.android/adbkey*
adb start-server
```

## Ollama

**Installation**: `brew install ollama` (CLI) and `brew install --cask ollama-app` (GUI, optional)  
**Purpose**: Run large language models locally

### Desktop GUI App

The Ollama desktop app (`ollama-app`) provides a graphical interface:

- **Chat Interface**: Clean, modern chat UI for interacting with models
- **Model Management**: Download, delete, and switch between models visually
- **File Support**: Drag and drop text, Markdown, PDFs, and code files
- **Streaming Responses**: Real-time streaming of model responses
- **Multimodal Support**: Context-aware conversations with file attachments

Launch from Applications or:
```bash
open -a Ollama
```

Both CLI and GUI share the same backend service - you can use either or both.

### Configuration

**Directory**: `ollama/` in dotfiles  
**Documentation**: `ollama/README.md`

Ollama stores models and data in `~/.ollama/` (created automatically). No symlinks needed as this is data storage, not configuration.

### Shell Aliases

Available in `.zshrc`:
- `ollama-list`: List all installed models
- `ollama-ps`: Show running models
- `ollama-pull`: Pull a model (usage: `ollama-pull llama3.2`)

### Service Management

```bash
# Start as background service
brew services start ollama

# Stop service
brew services stop ollama

# Run manually (without service)
ollama serve
```

### Common Commands

```bash
# List installed models
ollama list

# Pull a model
ollama pull llama3.2

# Run a model interactively
ollama run llama3.2

# Show model information
ollama show llama3.2

# List running models
ollama ps

# Stop a running model
ollama stop llama3.2

# Remove a model
ollama rm llama3.2
```

### Popular Models

- `llama3.2` - Meta's Llama 3.2 (3B parameters, fast)
- `llama3.1` - Meta's Llama 3.1 (8B parameters)
- `mistral` - Mistral AI's 7B model
- `codellama` - Code-focused Llama variant
- `phi3` - Microsoft's Phi-3 (small, fast)
- `gemma2` - Google's Gemma 2

### API Access

Ollama runs a local API server on `http://localhost:11434` by default.

```bash
# Example API call
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Why is the sky blue?",
  "stream": false
}'
```

### Environment Variables

- `OLLAMA_HOST` - Set the host and port (default: `localhost:11434`)
- `OLLAMA_MODELS` - Set custom models directory
- `OLLAMA_FLASH_ATTENTION` - Enable flash attention (set to `1`)
- `OLLAMA_KV_CACHE_TYPE` - Set KV cache type (e.g., `q8_0`)

### Integration

Ollama can be integrated with:
- **Cursor IDE**: Use Ollama as a local AI assistant
- **Command line**: Direct CLI access for quick queries
- **API clients**: Any HTTP client can interact with the API
- **Other tools**: Many tools support Ollama as a backend

### Notes

- Models are stored in `~/.ollama/models/` and can be large (several GB each)
- The service runs on port 11434 by default
- First model pull may take time depending on internet speed
- GPU acceleration is automatically used if available

## EditorConfig

**File**: `.editorconfig`  
**Linked to**: `~/.editorconfig`

Ensures consistent coding styles across editors:

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

## Troubleshooting

### Common Issues

1. **Git authentication**: Run `gh auth login`
2. **Docker not starting**: Check Docker Desktop is running
3. **Cursor extensions**: Use `bin/cursor-extensions` script
4. **Delta not working**: Ensure `git-delta` is installed

### Debug Commands

```bash
# Check Git configuration
git config --list

# Check GitHub CLI status
gh auth status

# Check Docker status
docker info

# Check Cursor extensions
cursor --list-extensions
```

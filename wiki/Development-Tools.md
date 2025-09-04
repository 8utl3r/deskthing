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

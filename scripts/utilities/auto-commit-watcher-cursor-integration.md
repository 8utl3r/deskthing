# Auto-Commit Watcher - Cursor Integration

This document explains how to integrate the auto-commit watcher with Cursor IDE.

## Features

1. **Directory Filtering**: Watch only specific directories
2. **Auto-Start with Cursor**: Automatically start/stop when Cursor opens/closes
3. **Status Display**: View current status in Cursor UI
4. **Settings Integration**: Configure via Cursor settings.json

## Configuration

### Cursor Settings

Edit `cursor/settings.json` (or use Cursor's Settings UI):

```json
{
  "autoCommitWatcher.enabled": true,
  "autoCommitWatcher.watchInterval": 30,
  "autoCommitWatcher.commitDelay": 5,
  "autoCommitWatcher.watchDirectories": [
    "scripts",
    "cursor",
    "hammerspoon",
    "karabiner",
    "macos"
  ],
  "autoCommitWatcher.excludeDirectories": [
    "scripts/state",
    "scripts/archive",
    ".git"
  ],
  "autoCommitWatcher.aiCommitPrompt": "Your custom prompt for AI commit messages",
  "autoCommitWatcher.autoStartWithCursor": true,
  "autoCommitWatcher.statusFile": "~/.auto_commit_watcher_status.json"
}
```

### Settings Explained

- **enabled**: Enable/disable the watcher (default: true)
- **watchInterval**: Seconds between checks for changes (default: 30)
- **commitDelay**: Seconds to wait after last change before committing (default: 5)
- **watchDirectories**: Array of directories to watch (empty = watch all)
- **excludeDirectories**: Directories to always exclude
- **aiCommitPrompt**: Custom prompt for AI commit message generation
- **autoStartWithCursor**: Auto-start when Cursor opens (default: true)
- **statusFile**: Path to status JSON file

## Auto-Start with Cursor

### Option 1: Cursor Tasks (Recommended)

The watcher can auto-start when you open a folder in Cursor using tasks.json:

1. Open Command Palette (⌘+Shift+P)
2. Run "Tasks: Run Task"
3. Select "Auto-Commit Watcher: Start"

Or it will auto-start if configured in tasks.json with `"runOn": "folderOpen"`.

### Option 2: Cursor Watcher Script

Run the cursor-watcher script to monitor Cursor app:

```bash
# Start cursor watcher (runs in background)
~/dotfiles/scripts/utilities/cursor-watcher &

# Or install as launchd service
cp ~/dotfiles/scripts/utilities/cursor-watcher.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/cursor-watcher.plist
```

### Option 3: Manual Start

```bash
# Start manually
~/dotfiles/scripts/utilities/auto-commit-watcher

# Or with custom settings
WATCH_INTERVAL=60 COMMIT_DELAY=10 ~/dotfiles/scripts/utilities/auto-commit-watcher
```

## Status Display

### View Status in Terminal

```bash
# Quick status
~/dotfiles/scripts/utilities/auto-commit-status-display.sh

# Or use jq directly
cat ~/.auto_commit_watcher_status.json | jq
```

### Status Values

- **idle**: Watching for changes
- **waiting**: Changes detected, waiting before commit
- **committing**: Currently committing
- **error**: Error occurred

### Status JSON Format

```json
{
  "status": "waiting",
  "message": "Changes detected, waiting 5s",
  "countdown": 3,
  "lastCommit": "refactor(scripts): improve logging",
  "timestamp": 1702324800,
  "lastCommitTime": "2025-01-11 18:00:00"
}
```

## Cursor UI Integration

### Option 1: Status Bar (VS Code Extension)

Create a simple VS Code extension to show status in the status bar. This requires:
- VS Code Extension API
- Status bar item that reads the JSON file
- Auto-refresh every few seconds

### Option 2: Terminal Panel

Keep a terminal open running:
```bash
watch -n 2 ~/dotfiles/scripts/utilities/auto-commit-status-display.sh
```

### Option 3: Tasks Panel

Use Cursor's Tasks panel:
1. Open Command Palette (⌘+Shift+P)
2. Run "Tasks: Run Task"
3. Select "Auto-Commit Watcher: Show Status (Formatted)"

## Directory Filtering

### Watch Specific Directories

In `cursor/settings.json`:
```json
{
  "autoCommitWatcher.watchDirectories": [
    "scripts",
    "cursor",
    "hammerspoon"
  ]
}
```

Only files in these directories will trigger commits.

### Exclude Directories

```json
{
  "autoCommitWatcher.excludeDirectories": [
    "scripts/state",
    "scripts/archive",
    ".git"
  ]
}
```

These directories are always ignored, even if in watchDirectories.

## AI Commit Message Customization

Customize the AI prompt in settings:

```json
{
  "autoCommitWatcher.aiCommitPrompt": "You are a git commit message generator. Focus on user-facing changes and technical improvements. Be concise and specific."
}
```

The prompt will be combined with file changes and git diff automatically.

## Troubleshooting

### Watcher Not Starting

1. Check if enabled in settings: `"autoCommitWatcher.enabled": true`
2. Check logs: `tail -f ~/.auto_commit_watcher.log`
3. Verify script is executable: `chmod +x ~/dotfiles/scripts/utilities/auto-commit-watcher`

### Status Not Updating

1. Check status file exists: `ls -la ~/.auto_commit_watcher_status.json`
2. Check file permissions
3. Verify watcher is running: `pgrep -f auto-commit-watcher`

### Directory Filtering Not Working

1. Verify settings are loaded: Check watcher logs for "Watching directories: ..."
2. Check directory names match exactly (case-sensitive)
3. Use relative paths from repo root

## Examples

### Watch Only Scripts

```json
{
  "autoCommitWatcher.watchDirectories": ["scripts"]
}
```

### Faster Commits

```json
{
  "autoCommitWatcher.watchInterval": 15,
  "autoCommitWatcher.commitDelay": 3
}
```

### Custom AI Prompt

```json
{
  "autoCommitWatcher.aiCommitPrompt": "Generate commit messages in the style of: 'what changed' not 'what was done'. Focus on the impact."
}
```


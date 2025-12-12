# Auto-Commit Watcher - Complete Feature Set

## ✅ Implemented Features

### 1. Directory Filtering ✅

**Configure in `cursor/settings.json`:**
```json
{
  "autoCommitWatcher.watchDirectories": [
    "scripts",
    "cursor",
    "hammerspoon",
    "karabiner",
    "macos"
  ]
}
```

- Only files in specified directories trigger commits
- Empty array = watch all directories
- Case-sensitive matching

### 2. Auto-Start/Stop with Cursor ✅

**Three options:**

#### Option A: Cursor Tasks (Recommended)
- Configured in `cursor/tasks.json`
- Auto-starts when folder opens (if `"runOn": "folderOpen"` is set)
- Can be started manually via Command Palette → Tasks

#### Option B: Cursor Watcher Script
```bash
# Start cursor watcher (monitors Cursor app)
~/dotfiles/scripts/utilities/cursor-watcher &

# Or install as service
cp ~/dotfiles/scripts/utilities/cursor-watcher.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/cursor-watcher.plist
```

#### Option C: Manual
```bash
~/dotfiles/scripts/utilities/auto-commit-watcher
```

### 3. Status Display ✅

**Status File:** `~/.auto_commit_watcher_status.json`

**View Status:**
```bash
# Quick formatted view
~/dotfiles/scripts/utilities/auto-commit-status-display.sh

# Raw JSON
cat ~/.auto_commit_watcher_status.json | jq

# Via Cursor Task
# Command Palette → Tasks → "Auto-Commit Watcher: Show Status (Formatted)"
```

**Status Values:**
- 🟢 **idle**: Watching for changes
- 🟡 **waiting**: Changes detected, countdown active
- 🔵 **committing**: Currently committing
- 🔴 **error**: Error occurred

**Status JSON:**
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

### 4. Cursor Settings Integration ✅

**All settings in `cursor/settings.json`:**

```json
{
  "autoCommitWatcher.enabled": true,
  "autoCommitWatcher.watchInterval": 30,
  "autoCommitWatcher.commitDelay": 5,
  "autoCommitWatcher.watchDirectories": ["scripts", "cursor"],
  "autoCommitWatcher.excludeDirectories": ["scripts/state"],
  "autoCommitWatcher.aiCommitPrompt": "Your custom prompt",
  "autoCommitWatcher.autoStartWithCursor": true,
  "autoCommitWatcher.statusFile": "~/.auto_commit_watcher_status.json"
}
```

**Settings are automatically loaded by the script!**

## UI Integration Options

### Option 1: Status Bar Extension (Advanced)

Create a VS Code extension (see `cursor-status-extension.md`):
- Shows status in Cursor's status bar
- Auto-updates every 2 seconds
- Click to see details
- Icons: 🟢 🟡 🔵 🔴

### Option 2: Terminal Panel (Simple)

Keep a terminal open:
```bash
watch -n 2 ~/dotfiles/scripts/utilities/auto-commit-status-display.sh
```

### Option 3: Tasks Panel

Use Cursor's built-in Tasks:
- Command Palette (⌘+Shift+P)
- "Tasks: Run Task"
- "Auto-Commit Watcher: Show Status (Formatted)"

### Option 4: Status File Monitoring

Use any file watcher to display status:
```bash
# Using fswatch (if installed)
fswatch ~/.auto_commit_watcher_status.json | while read; do
  ~/dotfiles/scripts/utilities/auto-commit-status-display.sh
done
```

## AI Commit Message Customization

**Customize the AI prompt in settings:**

```json
{
  "autoCommitWatcher.aiCommitPrompt": "You are a git commit message generator. Focus on user-facing changes. Be concise and specific about what changed and why."
}
```

The script automatically:
- Adds file list
- Adds git diff (first 4000 chars)
- Adds Conventional Commits requirements
- Validates output format

## Quick Start

1. **Configure settings** in `cursor/settings.json`
2. **Start watcher:**
   ```bash
   # Option A: Auto-start with Cursor (via tasks.json)
   # Just open the folder in Cursor
   
   # Option B: Use cursor-watcher
   ~/dotfiles/scripts/utilities/cursor-watcher &
   
   # Option C: Manual
   ~/dotfiles/scripts/utilities/auto-commit-watcher
   ```
3. **View status:**
   ```bash
   ~/dotfiles/scripts/utilities/auto-commit-status-display.sh
   ```

## Files Created

- `scripts/utilities/auto-commit-watcher` - Main script
- `scripts/utilities/cursor-watcher` - Cursor app monitor
- `scripts/utilities/auto-commit-status-display.sh` - Status display
- `scripts/utilities/auto-commit-watcher-config.json` - Config template
- `scripts/utilities/cursor-watcher.plist` - Launchd service
- `cursor/settings.json` - Updated with settings
- `cursor/tasks.json` - Task definitions
- `scripts/utilities/auto-commit-watcher-cursor-integration.md` - Full docs
- `scripts/utilities/cursor-status-extension.md` - Extension guide

## Next Steps

1. **Test the watcher:**
   ```bash
   cd ~/dotfiles
   ./scripts/utilities/auto-commit-watcher --dry-run
   ```

2. **Configure directories** in `cursor/settings.json`

3. **Set up auto-start:**
   - Use tasks.json (recommended)
   - Or install cursor-watcher service

4. **Create status bar extension** (optional, see `cursor-status-extension.md`)

5. **Customize AI prompt** for your commit style


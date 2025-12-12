# Auto-Commit Watcher - Detailed Quick Start Guide

This guide walks you through setting up the auto-commit watcher step-by-step with detailed explanations.

## Prerequisites

Before starting, ensure you have:
- ✅ Git repository initialized
- ✅ Cursor IDE installed
- ✅ `jq` installed (for reading settings): `brew install jq`
- ✅ Cursor Agent CLI installed (for AI commit messages): `curl https://cursor.com/install -fsS | bash`

## Step 1: Configure Settings in Cursor

### What This Does
The watcher reads configuration from Cursor's `settings.json` file. This allows you to control the watcher directly from Cursor's settings UI or by editing the JSON file.

### How to Configure

**Option A: Edit settings.json directly**
1. Open `~/dotfiles/cursor/settings.json` in Cursor
2. The settings are already added! You can modify them:
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
     ]
   }
   ```

**Option B: Use Cursor Settings UI**
1. Open Cursor Settings (⌘+,)
2. Search for "autoCommitWatcher"
3. Modify the settings as needed

### Settings Explained

- **enabled** (`true`/`false`): Master switch. Set to `false` to completely disable the watcher.
- **watchInterval** (`30`): How often (in seconds) the script checks for file changes. Lower = more responsive but more CPU usage.
- **commitDelay** (`5`): How long (in seconds) to wait after the last file change before committing. Prevents committing while you're still editing.
- **watchDirectories** (`[]`): Array of directory names to watch. Empty array `[]` = watch everything. Only files in these directories will trigger commits.
- **excludeDirectories** (`[]`): Directories to always ignore, even if in watchDirectories.
- **aiCommitPrompt** (`string`): Custom instructions for the AI when generating commit messages.
- **autoStartWithCursor** (`true`/`false`): Whether to auto-start when Cursor opens (requires additional setup).

### Example Configurations

**Watch only scripts:**
```json
{
  "autoCommitWatcher.watchDirectories": ["scripts"]
}
```

**Faster commits (check every 15s, commit after 3s):**
```json
{
  "autoCommitWatcher.watchInterval": 15,
  "autoCommitWatcher.commitDelay": 3
}
```

**Custom AI prompt:**
```json
{
  "autoCommitWatcher.aiCommitPrompt": "Generate commit messages that focus on user impact. Be very concise."
}
```

## Step 2: Choose Your Startup Method

You have three options for starting the watcher. Choose based on your preference:

### Option A: Cursor Tasks (Recommended for Development)

**What it does:** Uses Cursor's built-in task system to start the watcher when you open the folder.

**How it works:**
- Cursor reads `cursor/tasks.json`
- When configured with `"runOn": "folderOpen"`, it automatically runs the task
- The watcher runs in the background

**Setup:**
1. The task is already configured in `cursor/tasks.json`
2. Open your dotfiles folder in Cursor
3. The watcher should auto-start (check with status command)

**Manual control:**
- Start: Command Palette (⌘+Shift+P) → "Tasks: Run Task" → "Auto-Commit Watcher: Start"
- Stop: Command Palette → "Tasks: Run Task" → "Auto-Commit Watcher: Stop"
- Status: Command Palette → "Tasks: Run Task" → "Auto-Commit Watcher: Show Status (Formatted)"

**Pros:**
- Integrated with Cursor
- Easy to start/stop from UI
- Auto-starts when folder opens

**Cons:**
- Only runs when Cursor is open
- Stops when Cursor closes

### Option B: Cursor Watcher Script (Recommended for Always-On)

**What it does:** A separate script monitors whether Cursor is running and starts/stops the auto-commit watcher accordingly.

**How it works:**
- Script checks every 5 seconds if Cursor app is running
- If Cursor is running → starts auto-commit-watcher
- If Cursor closes → stops auto-commit-watcher

**Setup:**

**Temporary (for testing):**
```bash
# Start in background
~/dotfiles/scripts/utilities/cursor-watcher &

# Check if it's running
ps aux | grep cursor-watcher

# Stop it
pkill -f cursor-watcher
```

**Permanent (as macOS service):**
```bash
# 1. Copy the service file
cp ~/dotfiles/scripts/utilities/cursor-watcher.plist ~/Library/LaunchAgents/

# 2. Load the service
launchctl load ~/Library/LaunchAgents/cursor-watcher.plist

# 3. Start it
launchctl start com.pete.cursor-watcher

# 4. Check status
launchctl list | grep cursor-watcher

# To stop/remove:
launchctl stop com.pete.cursor-watcher
launchctl unload ~/Library/LaunchAgents/cursor-watcher.plist
```

**Pros:**
- Runs independently of Cursor
- Auto-starts/stops with Cursor app
- Survives Cursor crashes

**Cons:**
- Requires separate service management
- More complex setup

### Option C: Manual Start (For Testing/One-Time Use)

**What it does:** Start the watcher manually when you want it.

**How it works:**
- Run the script directly
- It runs until you stop it (Ctrl+C) or close terminal

**Setup:**
```bash
# Start in foreground (see all output)
cd ~/dotfiles
./scripts/utilities/auto-commit-watcher

# Start in background
./scripts/utilities/auto-commit-watcher &

# Stop it
pkill -f auto-commit-watcher
```

**With custom settings (override config):**
```bash
# Faster checking
WATCH_INTERVAL=15 COMMIT_DELAY=3 ./scripts/utilities/auto-commit-watcher

# Dry-run (test without committing)
./scripts/utilities/auto-commit-watcher --dry-run
```

**Pros:**
- Full control
- See all output
- Easy to test

**Cons:**
- Must remember to start
- Stops when terminal closes

## Step 3: Verify It's Working

### Check if Watcher is Running

```bash
# Check process
ps aux | grep auto-commit-watcher | grep -v grep

# Should show something like:
# pete  12345  ...  ./scripts/utilities/auto-commit-watcher
```

### View Status

**Quick status display:**
```bash
~/dotfiles/scripts/utilities/auto-commit-status-display.sh
```

**Output examples:**
- `🟢 Watching for changes` - Idle, waiting
- `🟡 Changes detected, waiting 5s (3s)` - Changes found, countdown active
- `🔵 Committing changes...` - Currently committing
- `🟢 Last commit: refactor(scripts): improve logging` - Just committed

**Raw JSON status:**
```bash
cat ~/.auto_commit_watcher_status.json | jq
```

**Via Cursor Task:**
- Command Palette (⌘+Shift+P)
- "Tasks: Run Task"
- "Auto-Commit Watcher: Show Status (Formatted)"

### Test It

1. **Make a test change:**
   ```bash
   cd ~/dotfiles
   echo "# Test" >> scripts/utilities/test-file.md
   ```

2. **Watch the logs:**
   ```bash
   tail -f ~/.auto_commit_watcher.log
   ```

3. **Check status:**
   ```bash
   ~/dotfiles/scripts/utilities/auto-commit-status-display.sh
   ```

4. **Expected behavior:**
   - Within 30 seconds: "Changes detected" message
   - After 5 seconds of no changes: "Committing changes..."
   - Then: "Committed" and "Pushed"

5. **Verify commit:**
   ```bash
   git log --oneline -1
   git show HEAD --stat
   ```

## Step 4: View Status in Cursor UI

### Method 1: Terminal Panel (Easiest)

Keep a terminal open in Cursor showing status:

```bash
# In Cursor's integrated terminal
watch -n 2 ~/dotfiles/scripts/utilities/auto-commit-status-display.sh
```

This updates every 2 seconds and shows:
- Current status with emoji
- Countdown timer (if waiting)
- Last commit message

### Method 2: Tasks Panel

1. Open Command Palette (⌘+Shift+P)
2. Type "Tasks: Run Task"
3. Select "Auto-Commit Watcher: Show Status (Formatted)"
4. Output appears in terminal panel

### Method 3: Status Bar Extension (Advanced)

For a permanent status bar item, create a VS Code extension (see `cursor-status-extension.md` for full instructions).

**Quick version:**
1. Install VS Code extension generator: `npm install -g yo generator-code`
2. Create extension: `yo code` (select TypeScript extension)
3. Copy code from `cursor-status-extension.md`
4. Build and install in Cursor

This gives you a status bar item that:
- Shows current status with icon
- Updates automatically every 2 seconds
- Click to see details

## Step 5: Customize for Your Workflow

### Adjust Timing

**For faster commits (if you edit quickly):**
```json
{
  "autoCommitWatcher.watchInterval": 15,
  "autoCommitWatcher.commitDelay": 3
}
```

**For slower commits (if you edit slowly):**
```json
{
  "autoCommitWatcher.watchInterval": 60,
  "autoCommitWatcher.commitDelay": 10
}
```

### Restrict to Specific Directories

**Only watch your main configs:**
```json
{
  "autoCommitWatcher.watchDirectories": [
    "cursor",
    "hammerspoon",
    "karabiner"
  ]
}
```

**Watch everything except state files:**
```json
{
  "autoCommitWatcher.watchDirectories": [],
  "autoCommitWatcher.excludeDirectories": [
    "scripts/state",
    "scripts/archive"
  ]
}
```

### Customize AI Commit Messages

**Focus on user impact:**
```json
{
  "autoCommitWatcher.aiCommitPrompt": "Generate commit messages that explain what the user will notice or benefit from. Be specific about the change."
}
```

**Technical focus:**
```json
{
  "autoCommitWatcher.aiCommitPrompt": "Generate technical commit messages focusing on implementation details and code changes."
}
```

## Troubleshooting

### Watcher Not Starting

**Check:**
1. Is it enabled? `jq -r '.["autoCommitWatcher.enabled"]' ~/Library/Application\ Support/Cursor/User/settings.json`
2. Check logs: `tail ~/.auto_commit_watcher.log`
3. Check if already running: `ps aux | grep auto-commit-watcher`
4. Verify script is executable: `ls -la ~/dotfiles/scripts/utilities/auto-commit-watcher`

**Fix:**
```bash
# Make executable
chmod +x ~/dotfiles/scripts/utilities/auto-commit-watcher

# Check for errors
~/dotfiles/scripts/utilities/auto-commit-watcher --dry-run
```

### Status Not Updating

**Check:**
1. Status file exists: `ls -la ~/.auto_commit_watcher_status.json`
2. File is readable: `cat ~/.auto_commit_watcher_status.json`
3. Watcher is running: `ps aux | grep auto-commit-watcher`

**Fix:**
```bash
# Recreate status file
echo '{"status":"idle","message":"Watching"}' > ~/.auto_commit_watcher_status.json

# Restart watcher
pkill -f auto-commit-watcher
~/dotfiles/scripts/utilities/auto-commit-watcher &
```

### Commits Not Happening

**Check:**
1. Are there changes? `git status`
2. Are changes in watched directories?
3. Check logs: `tail -f ~/.auto_commit_watcher.log`
4. Test with dry-run: `./scripts/utilities/auto-commit-watcher --dry-run`

**Common issues:**
- Files in ignored directories (check `excludeDirectories`)
- Files outside `watchDirectories` (if set)
- Git not configured properly
- No write access to repo

### AI Commit Messages Not Working

**Check:**
1. Cursor Agent CLI installed? `cursor-agent --version`
2. Check logs for AI errors: `grep -i "ai\|cursor" ~/.auto_commit_watcher.log`

**Fix:**
```bash
# Install Cursor Agent CLI
curl https://cursor.com/install -fsS | bash

# Verify
cursor-agent --version

# Test
cursor-agent --print "test" --output-format text
```

## Daily Usage

### Normal Workflow

1. **Open Cursor** → Watcher auto-starts (if configured)
2. **Make changes** → Watcher detects automatically
3. **Wait 5 seconds** (or your configured delay)
4. **Auto-commit** → Changes committed and pushed
5. **Check status** → See last commit in status display

### Making Changes

Just edit files normally! The watcher:
- Detects changes every 30 seconds (or your interval)
- Waits 5 seconds after last change (or your delay)
- Commits automatically
- Pushes to remote

### Viewing History

```bash
# Recent commits
git log --oneline -10

# See what was auto-committed
git log --oneline --grep="refactor\|chore\|config\|docs" -20

# Last commit details
git show HEAD
```

### Stopping the Watcher

**If using Tasks:**
- Command Palette → "Tasks: Run Task" → "Auto-Commit Watcher: Stop"

**If using cursor-watcher:**
```bash
pkill -f cursor-watcher
# Or if using launchd:
launchctl stop com.pete.cursor-watcher
```

**If running manually:**
- Press Ctrl+C in the terminal
- Or: `pkill -f auto-commit-watcher`

## Advanced: Status Bar Integration

For a permanent status display in Cursor's status bar, you need to create a VS Code extension. See `cursor-status-extension.md` for complete instructions.

**Quick overview:**
1. Extension shows status bar item
2. Updates every 2 seconds automatically
3. Click to see full details
4. Icons: 🟢 (idle), 🟡 (waiting), 🔵 (committing), 🔴 (error)

## Next Steps

1. ✅ **Test it:** Make a small change and watch it commit
2. ✅ **Customize:** Adjust settings for your workflow
3. ✅ **Set up auto-start:** Choose your preferred method
4. ✅ **Monitor:** Set up status display
5. ✅ **Optional:** Create status bar extension for permanent UI

## Getting Help

- **Logs:** `tail -f ~/.auto_commit_watcher.log`
- **Status:** `cat ~/.auto_commit_watcher_status.json | jq`
- **Test mode:** `./scripts/utilities/auto-commit-watcher --dry-run`
- **Documentation:** See `AUTO_COMMIT_WATCHER.md` and `AUTO_COMMIT_FEATURES.md`


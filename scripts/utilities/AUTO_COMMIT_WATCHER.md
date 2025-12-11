# Auto-Commit Watcher

Automatically commits and pushes changes to your dotfiles repository using Cursor CLI for AI-generated commit messages.

## Features

- **AI-Generated Commit Messages**: Uses Cursor CLI to generate conventional commit messages
- **Smart File Watching**: Monitors for changes and commits after a delay period
- **Automatic Push**: Pushes commits to remote repository automatically
- **Safety Features**: Dry-run mode, configurable delays, file exclusions
- **Background Service**: Can run as a macOS launchd service

## Installation

### 1. Install Cursor CLI (if needed)

The script uses the Cursor binary from your installed Cursor.app. If you need the separate CLI:

```bash
curl https://cursor.com/install -fsS | bash
```

### 2. Test the Script

Run in dry-run mode first to see what it would do:

```bash
cd ~/dotfiles
./scripts/utilities/auto-commit-watcher --dry-run
```

### 3. Run Manually

```bash
# Start the watcher
./scripts/utilities/auto-commit-watcher

# Or with custom settings
WATCH_INTERVAL=60 COMMIT_DELAY=10 ./scripts/utilities/auto-commit-watcher
```

### 4. Run as Background Service (macOS)

Install as a launchd service:

```bash
# Copy plist to LaunchAgents
cp ~/dotfiles/scripts/utilities/auto-commit-watcher.plist ~/Library/LaunchAgents/

# Load the service
launchctl load ~/Library/LaunchAgents/auto-commit-watcher.plist

# Start the service
launchctl start com.pete.auto-commit-watcher
```

To stop the service:

```bash
launchctl stop com.pete.auto-commit-watcher
launchctl unload ~/Library/LaunchAgents/auto-commit-watcher.plist
```

## Configuration

### Environment Variables

- `WATCH_INTERVAL`: Seconds between checks for changes (default: 30)
- `COMMIT_DELAY`: Seconds to wait after last change before committing (default: 5)
- `DRY_RUN`: Set to 1 for dry-run mode (default: 0)
- `ENABLED`: Set to 0 to disable, 1 to enable (default: 1)
- `LOG_FILE`: Path to log file (default: ~/.auto_commit_watcher.log)

### Ignored Files/Patterns

The script automatically ignores:
- `*.log`, `*.tmp`
- `.DS_Store`
- `node_modules/`
- `.git/`
- `scripts/state/`
- `*.iso`

You can modify the `IGNORE_PATTERNS` array in the script to add more patterns.

## Usage

### Basic Usage

```bash
# Start watcher (runs in foreground)
./scripts/utilities/auto-commit-watcher

# Test without committing
./scripts/utilities/auto-commit-watcher --dry-run

# Disable temporarily
ENABLED=0 ./scripts/utilities/auto-commit-watcher
```

### Custom Settings

```bash
# Check every 60 seconds, wait 10 seconds after changes
WATCH_INTERVAL=60 COMMIT_DELAY=10 ./scripts/utilities/auto-commit-watcher

# More aggressive (check every 15s, commit after 3s)
WATCH_INTERVAL=15 COMMIT_DELAY=3 ./scripts/utilities/auto-commit-watcher
```

## How It Works

1. **Watches for Changes**: Polls git status every `WATCH_INTERVAL` seconds
2. **Waits for Stability**: After detecting changes, waits `COMMIT_DELAY` seconds to ensure no more changes
3. **Generates Commit Message**: Uses Cursor CLI to generate a conventional commit message
4. **Commits**: Stages all changes and commits with the generated message
5. **Pushes**: Automatically pushes to `origin/main`

## Commit Message Generation

The script attempts to use Cursor CLI to generate commit messages. If Cursor CLI is unavailable or fails, it falls back to a simple heuristic-based message generator that:
- Detects documentation changes → `docs: update documentation`
- Detects config changes → `config: update configuration`
- Detects script changes → `refactor: update scripts`
- Default → `chore: update N file(s)`

## Safety Features

- **Dry-Run Mode**: Test without committing
- **File Exclusions**: Automatically ignores temporary and system files
- **Lock File**: Prevents multiple instances from running
- **Error Handling**: Graceful error handling and logging
- **Delay Period**: Waits for changes to stabilize before committing

## Logging

Logs are written to `~/.auto_commit_watcher.log` by default. You can view recent activity:

```bash
tail -f ~/.auto_commit_watcher.log
```

If running as a service, also check:
- `~/.auto_commit_watcher.out.log` (stdout)
- `~/.auto_commit_watcher.err.log` (stderr)

## Troubleshooting

### Script doesn't commit

1. Check if it's enabled: `ENABLED=1`
2. Check logs: `tail ~/.auto_commit_watcher.log`
3. Run in dry-run mode to see what it detects
4. Verify git repository is clean and on correct branch

### Cursor CLI not working

The script will fall back to simple commit messages if Cursor CLI fails. This is normal and the script will still work.

### Service not starting

1. Check service status: `launchctl list | grep auto-commit`
2. Check error log: `cat ~/.auto_commit_watcher.err.log`
3. Verify plist syntax: `plutil -lint ~/Library/LaunchAgents/auto-commit-watcher.plist`

### Too many commits

Increase `COMMIT_DELAY` to wait longer after changes before committing:

```bash
COMMIT_DELAY=30 ./scripts/utilities/auto-commit-watcher
```

## Integration with Dotfiles

This script is part of your dotfiles repository and can be managed like other scripts:

```bash
# Link the script (if you want it in PATH)
ln -s ~/dotfiles/scripts/utilities/auto-commit-watcher ~/bin/auto-commit-watcher
```

## Notes

- The script commits ALL changes (except ignored files) - be careful with sensitive data
- Commit messages are AI-generated but may need manual review
- The script pushes to `origin/main` - ensure your branch is set correctly
- Consider using this only for dotfiles repository, not for production code

# Auto-Commit Watcher - Summary

## How It Works (Simple Version)

1. **Coding agent makes changes** → Adds commit message via:
   - `.auto_commit_message` file, OR
   - `# AUTO_COMMIT: message` comment in changed files

2. **Script detects changes** → Every 30 seconds (configurable)

3. **Script extracts message** → Looks for AUTO_COMMIT message

4. **Script commits** → After 5 seconds of no new changes (configurable)

5. **Script pushes** → Automatically to origin/main

6. **Script cleans up** → Deletes `.auto_commit_message` file after commit

## For Coding Agent

**ALWAYS add commit message when making changes:**

```bash
# Option 1: File (preferred for multi-file changes)
echo "type(scope): description" > .auto_commit_message

# Option 2: Comment in changed file
# AUTO_COMMIT: type(scope): description
```

**See `CODING_AGENT_INSTRUCTIONS.md` for full details.**

## Configuration

All in `cursor/settings.json`:
- `autoCommitWatcher.enabled`: Enable/disable
- `autoCommitWatcher.watchInterval`: Check frequency (seconds)
- `autoCommitWatcher.commitDelay`: Wait time before commit (seconds)
- `autoCommitWatcher.watchDirectories`: Which directories to watch
- `autoCommitWatcher.excludeDirectories`: Always ignore these

## Status

View current status:
```bash
~/dotfiles/scripts/utilities/auto-commit-status-display.sh
```

Or check JSON:
```bash
cat ~/.auto_commit_watcher_status.json | jq
```

## Quick Start

1. Make changes
2. Add commit message (`.auto_commit_message` or comment)
3. Script auto-commits after delay
4. Done!

No AI CLI needed - just add the message when you make changes.

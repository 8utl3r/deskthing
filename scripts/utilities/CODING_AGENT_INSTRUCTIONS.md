# Instructions for Coding Agent: AUTO_COMMIT Messages

**CRITICAL:** When making code changes, you MUST add a commit message that the auto-commit watcher can use.

## Required Action After Every Change

After making any code changes, add ONE of the following:

### Option 1: Create .auto_commit_message File (PREFERRED)

```bash
echo "type(scope): description" > .auto_commit_message
```

**Example:**
```bash
echo "refactor(scripts): simplify commit message extraction" > .auto_commit_message
```

**When to use:**
- Multiple files changed
- Complex changes
- Want explicit control

### Option 2: Add AUTO_COMMIT Comment to Changed Files

Add a comment at the top of the file(s) you're changing:

**For shell scripts:**
```bash
#!/usr/bin/env bash
# AUTO_COMMIT: refactor(scripts): improve error handling
```

**For JSON files:**
```json
{
  // AUTO_COMMIT: config: update cursor settings
  "setting": "value"
}
```

**For Markdown:**
```markdown
<!-- AUTO_COMMIT: docs: add coding agent instructions -->
# Title
```

**For Lua:**
```lua
-- AUTO_COMMIT: refactor(hammerspoon): reorganize modules
```

## Commit Message Format

**MUST follow Conventional Commits:**
```
type(scope): description
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `refactor`: Code restructuring
- `config`: Configuration changes
- `chore`: Maintenance

**Examples:**
- `feat(cursor): add auto-commit watcher integration`
- `fix(scripts): correct path resolution bug`
- `refactor(hammerspoon): reorganize into modules`
- `docs: update quick start guide`
- `config: update cursor settings`

## Workflow

1. **Make your code changes**
2. **Immediately add commit message:**
   - Create `.auto_commit_message` file, OR
   - Add `# AUTO_COMMIT: message` comment to changed file(s)
3. **Script will detect and use it automatically**

## What Happens

- Script checks for `.auto_commit_message` file first
- If not found, looks for `AUTO_COMMIT:` comments in changed files
- Uses the message when committing
- Deletes `.auto_commit_message` after successful commit
- Falls back to simple heuristic if no message found

## Examples

### Example 1: Single File Change
```bash
# Editing scripts/utilities/auto-commit-watcher
# Add at top of file:
#!/usr/bin/env bash
# AUTO_COMMIT: refactor(scripts): simplify message extraction
```

### Example 2: Multiple Files
```bash
# Create message file once:
echo "feat: add auto-commit watcher with cursor integration" > .auto_commit_message
# ... make changes to multiple files
# Script uses this one message for all changes
```

### Example 3: Config Change
```json
{
  // AUTO_COMMIT: config(cursor): add watcher settings
  "autoCommitWatcher.enabled": true
}
```

## Important Notes

- **Always add commit message** - don't rely on fallback
- **Be specific** - explain what changed and why
- **Use Conventional Commits** format
- **File-based is preferred** for multi-file changes
- **Comment-based works** for single-file changes

## Enforcement

The auto-commit watcher will:
1. Look for your commit message
2. Use it if found
3. Fall back to generic message if not found (not ideal!)

**Always add the commit message to ensure meaningful commits!**

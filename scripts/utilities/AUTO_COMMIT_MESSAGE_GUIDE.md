# AUTO_COMMIT Message Guide

The auto-commit watcher looks for commit messages in your code changes. When the coding agent makes changes, it should include an AUTO_COMMIT comment that the script will use.

## How It Works

The script looks for commit messages in this order:
1. **`.auto_commit_message` file** (highest priority) - in repo root
2. **AUTO_COMMIT comments** in changed files

After a successful commit, the `.auto_commit_message` file is automatically deleted.

## Method 1: .auto_commit_message File (Recommended)

Create a file in the repo root with your commit message:

```bash
echo "refactor(scripts): improve auto-commit watcher logging" > .auto_commit_message
```

**Pros:**
- Simple and explicit
- Works for any file type
- Easy to see what will be committed
- Automatically deleted after commit

**Example:**
```bash
# When making changes, create the file:
echo "feat(cursor): add auto-commit watcher settings" > .auto_commit_message

# Make your changes...
# Script will use this message when committing
```

## Method 2: AUTO_COMMIT Comments in Files

Add a comment at the top of changed files with the commit message.

### For Shell/Python/Lua Scripts:
```bash
#!/usr/bin/env bash
# AUTO_COMMIT: refactor(scripts): improve error handling

# ... rest of script
```

### For JSON/Config Files:
```json
{
  // AUTO_COMMIT: config: update cursor settings
  "setting": "value"
}
```

### For Markdown/Documentation:
```markdown
<!-- AUTO_COMMIT: docs: add auto-commit message guide -->
# Guide Title
```

### For Other Languages:
- **JavaScript/TypeScript**: `// AUTO_COMMIT: message`
- **Python**: `# AUTO_COMMIT: message`
- **Lua**: `-- AUTO_COMMIT: message`
- **HTML/XML**: `<!-- AUTO_COMMIT: message -->`

## Commit Message Format

Follow Conventional Commits format:
```
type(scope): description
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting, no code change
- `refactor`: Code restructuring
- `perf`: Performance improvement
- `test`: Adding tests
- `chore`: Maintenance tasks
- `config`: Configuration changes

**Examples:**
```
feat(cursor): add auto-commit watcher integration
fix(scripts): correct path resolution in watcher
docs: update quick start guide
refactor(hammerspoon): reorganize modules
config: update cursor settings
```

## Instructions for Coding Agent

**When making changes, ALWAYS add one of:**

1. **Create `.auto_commit_message` file:**
   ```bash
   echo "type(scope): description" > .auto_commit_message
   ```

2. **Or add comment to changed files:**
   ```bash
   # AUTO_COMMIT: type(scope): description
   ```

**The commit message should:**
- Follow Conventional Commits format
- Be specific about what changed
- Explain why it matters
- Be concise (under 72 characters)

**After changes are committed, the script will:**
- Use the message from `.auto_commit_message` or comments
- Delete `.auto_commit_message` file automatically
- Fall back to heuristic message if none found

## Examples

### Example 1: File-based
```bash
# Making changes to cursor settings
echo "config(cursor): add auto-commit watcher settings" > .auto_commit_message
# ... make changes to cursor/settings.json
# Script will commit with this message
```

### Example 2: Comment-based
```bash
# In scripts/utilities/auto-commit-watcher:
#!/usr/bin/env bash
# AUTO_COMMIT: refactor(scripts): simplify commit message generation
# ... rest of script
```

### Example 3: Multiple files changed
```bash
# Create .auto_commit_message once for all changes:
echo "feat: add auto-commit watcher with cursor integration" > .auto_commit_message
# ... make changes to multiple files
# Script will use this one message for all changes
```

## Fallback Behavior

If no AUTO_COMMIT message is found, the script uses a simple heuristic:
- Documentation files → `docs: update documentation`
- Config files → `config: update configuration`
- Scripts → `refactor: update scripts`
- Other → `chore: update N file(s)`

## Best Practices

1. **Always add commit message** when making changes
2. **Use `.auto_commit_message` file** for multi-file changes
3. **Use comments** for single-file changes
4. **Be specific** - explain what and why
5. **Follow Conventional Commits** format

## Troubleshooting

**Message not being used?**
- Check file exists: `ls -la .auto_commit_message`
- Check comment format matches exactly: `# AUTO_COMMIT: message`
- Check file is in watched directory (if `watchDirectories` is set)

**Message deleted before commit?**
- The file is only deleted AFTER successful commit
- If commit fails, file remains for next attempt

**Want to change message?**
- Just update `.auto_commit_message` or comment
- Script will use the new message on next commit cycle

# Jujutsu VCS Usage Guide

## Installation

### macOS

```bash
brew install jj
```

### Linux

**Arch Linux:**
```bash
pacman -S jujutsu
```

**Other distributions:**
- Check the official documentation for package availability
- Or build from source

### Windows

- Download pre-built binaries from the official repository
- Or build from source

### Build from Source

```bash
git clone https://github.com/jj-vcs/jj.git
cd jj
cargo build --release
```

## Initial Setup

### Configure User Information

```bash
jj config set --user user.name "Your Name"
jj config set --user user.email "your.email@example.com"
```

This ensures commits are properly attributed.

## Basic Workflows

### Initialize a New Repository

```bash
jj init
```

Creates a new Jujutsu repository in the current directory.

### Clone a Git Repository

```bash
jj git clone <repository_url>
```

Example:
```bash
jj git clone https://github.com/jj-vcs/jj.git
```

This clones the Git repository and sets up Jujutsu to work with it. You can use both Jujutsu and Git commands in the same repository.

### Convert Existing Git Repository

If you have an existing Git repository:

```bash
cd /path/to/git/repo
jj git init
```

This initializes Jujutsu in your current Git repository, enabling Jujutsu commands alongside Git.

## Common Commands

### Status and Viewing Changes

```bash
# Check repository status
jj status

# View changes in working copy
jj diff

# View commit log
jj log

# View log with graph
jj log -G
```

### Creating and Managing Changes

```bash
# Create a new change based on main
jj new main

# Create a new change with a description
jj new -m "Add new feature"

# Describe/update commit message
jj describe -m "Updated commit message"

# Edit a specific commit
jj edit <change-id>

# Abandon a change
jj abandon <change-id>
```

### Committing Changes

In Jujutsu, the working copy is automatically a commit. To finalize:

```bash
# Commit with message
jj commit -m "Your commit message"

# Or just describe the change (it's already committed)
jj describe -m "Your commit message"
```

### Working with Branches/Bookmarks

```bash
# List bookmarks
jj branch list

# Create/set a bookmark
jj branch set <branch-name>

# Delete a bookmark
jj branch delete <branch-name>

# Push bookmark to Git remote
jj git push -b <branch-name>
```

### Undo Operations

```bash
# Undo the last operation
jj undo

# Undo multiple operations (run multiple times)
jj undo
jj undo

# View operation log
jj op log

# Restore to a specific operation
jj op restore <operation-id>
```

### Merging and Rebasing

```bash
# Merge changes
jj merge <change-id>

# Rebase a change onto another
jj rebase -d <target-change>

# Rebase current change
jj rebase -d main
```

### Splitting Changes

```bash
# Split a change into multiple changes
jj split

# Move parts of a change to a new change
jj move -r <source> -d <destination>
```

## Advanced Workflows

### Working with Conflicts

```bash
# Create a new change on top of conflicted commit
jj new <conflicted-commit>

# Edit conflicted files (conflicts shown with markers)
# ... resolve conflicts in editor ...

# Inspect resolution
jj diff

# Merge resolution into original commit
jj squash
```

### History Editing

```bash
# Edit an old commit
jj edit <old-change-id>
# ... make changes ...
# Descendant commits automatically rebase

# Squash changes together
jj squash -r <source> -d <destination>

# Move a change to a different parent
jj rebase -d <new-parent>
```

### Git Integration

```bash
# Fetch from Git remote
jj git fetch

# Push to Git remote
jj git push -b <branch-name>

# Pull from Git remote
jj git pull

# Sync bookmarks with Git branches
jj git sync
```

## Migration from Git

### Step-by-Step Migration

1. **Initialize Jujutsu in existing repo:**
   ```bash
   cd /path/to/git/repo
   jj git init
   ```

2. **Start using Jujutsu commands:**
   - Use `jj status` instead of `git status`
   - Use `jj new` instead of `git checkout -b`
   - Use `jj commit` instead of `git add` + `git commit`

3. **Sync with Git:**
   - Bookmarks automatically sync with Git branches
   - Use `jj git push` to push to Git remotes
   - Git users can continue using Git commands

4. **Gradual adoption:**
   - Team members can mix Git and Jujutsu
   - No need for everyone to switch at once
   - Can always fall back to Git if needed

### Common Git to Jujutsu Mappings

| Git Command | Jujutsu Equivalent |
|------------|-------------------|
| `git status` | `jj status` |
| `git add <file>` | (automatic, no equivalent) |
| `git commit -m "msg"` | `jj describe -m "msg"` or `jj commit -m "msg"` |
| `git checkout -b branch` | `jj new main` then `jj branch set branch` |
| `git branch` | `jj branch list` |
| `git log` | `jj log` |
| `git diff` | `jj diff` |
| `git rebase -i` | `jj edit` (automatic rebasing) |
| `git merge` | `jj merge` |
| `git push` | `jj git push -b <branch>` |
| `git pull` | `jj git pull` |

## Best Practices

### Commit Messages

- Use descriptive messages: `jj describe -m "Add user authentication"`
- Follow conventional commits if your team uses them
- Update messages as needed: `jj describe -m "Updated message"`

### Working with Multiple Changes

```bash
# Create multiple changes in parallel
jj new main -m "Feature A"
# ... work on feature A ...

jj new main -m "Feature B"
# ... work on feature B ...

# Switch between changes
jj new <change-id>
```

### Collaboration Workflow

1. **Fetch latest changes:**
   ```bash
   jj git fetch
   ```

2. **Create your change:**
   ```bash
   jj new main -m "Your feature"
   ```

3. **Work and commit:**
   - Edit files (automatically tracked)
   - `jj describe -m "Update message"` as needed

4. **Push to remote:**
   ```bash
   jj branch set feature-name
   jj git push -b feature-name
   ```

### Handling Large Repositories

- Initialization may be slow for very large repos
- Consider using Jujutsu for new work, Git for history
- Performance improves with smaller, focused repositories

## Troubleshooting

### Undo Mistakes

```bash
# Undo last operation
jj undo

# See what operations are available
jj op log

# Restore to specific state
jj op restore <operation-id>
```

### Resolve Conflicts

```bash
# View conflicts
jj status

# Create resolution commit
jj new <conflicted-commit>

# Edit files to resolve
# ... edit ...

# Merge resolution
jj squash
```

### Sync Issues with Git

```bash
# Force sync bookmarks
jj git sync --all

# Check Git status
git status  # Still works!

# Manually export bookmarks
jj git push --all
```

## Integration with Tools

### Editor Integration

- **Neovim**: `jj.nvim` plugin available
- **VS Code**: Limited support (mostly CLI-based)
- **Other editors**: Primarily CLI-based for now

### CI/CD

- Jujutsu works with Git remotes
- Most CI/CD systems work with Git
- Use `jj git push` to push changes
- CI systems see standard Git commits

## Resources

- **Official Documentation**: https://jj-vcs.github.io/jj/latest/
- **Tutorial**: https://jj-for-everyone.github.io/
- **GitHub Repository**: https://github.com/jj-vcs/jj
- **CLI Reference**: https://jj-vcs.github.io/jj/latest/cli-reference/

## Summary

Jujutsu simplifies version control by:
- Eliminating the staging area
- Automating rebasing
- Providing undo for everything
- Maintaining Git compatibility

Start with basic commands and gradually explore advanced features as you become comfortable with the workflow.

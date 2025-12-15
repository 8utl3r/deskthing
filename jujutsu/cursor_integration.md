# Integrating Jujutsu VCS with Cursor IDE

## Overview

Since Jujutsu is Git-compatible, it works seamlessly with existing Git hosting services (GitHub, GitLab, Bitbucket) without requiring a separate hosting platform. For Cursor IDE integration, you can use the "Jujutsu Kaizen" (jjk) extension, which provides Jujutsu VCS support for VS Code-based editors like Cursor.

## Cursor IDE Integration

### Installing the Jujutsu Extension

Cursor is built on VS Code architecture, so VS Code extensions work with Cursor. To add Jujutsu support:

1. **Open Extensions View**
   - Press `Cmd+Shift+X` (macOS) or `Ctrl+Shift+X` (Windows/Linux)
   - Or click the Extensions icon in the sidebar

2. **Search for "jjk" or "Jujutsu Kaizen"**
   - Extension ID: `keanemind.jjk`
   - Repository: https://github.com/keanemind/jjk

3. **Install the Extension**
   - Click "Install"
   - The extension provides Jujutsu VCS support for VS Code/Cursor

### Extension Features

The jjk extension provides:

- **File Status Tracking**: See which files have changes
- **Detailed Diffs**: View changes in the editor
- **Change Management**: Stage, commit, and manage changes
- **Revision History**: Navigate commit history
- **Branch/Bookmark Management**: Work with bookmarks (Jujutsu's equivalent of branches)

### Configuration

#### 1. Ensure Jujutsu is Installed

First, make sure Jujutsu is installed and in your PATH:

```bash
# Check if jj is available
which jj
jj --version

# If not installed, install it:
# macOS
brew install jj

# Or build from source
```

#### 2. Configure Extension Settings

Add to your Cursor `settings.json`:

```json
{
  // Jujutsu extension settings
  "jjk.jjPath": "jj",  // Path to jj executable (default: "jj")
  
  // Optional: Customize behavior
  "jjk.enabled": true,
  "jjk.showStatusBar": true
}
```

If `jj` is not in your PATH, specify the full path:

```json
{
  "jjk.jjPath": "/usr/local/bin/jj"  // or wherever jj is installed
}
```

#### 3. Initialize Jujutsu in Your Repository

If you have an existing Git repository:

```bash
cd /path/to/your/repo
jj git init
```

This initializes Jujutsu in your Git repository, allowing you to use both Git and Jujutsu commands.

### Using Jujutsu in Cursor

Once the extension is installed and configured:

1. **Open a Repository**
   - Open a folder that contains a Git repository (or initialize Jujutsu in it)

2. **Source Control View**
   - The Source Control panel (sidebar) will show Jujutsu status
   - You'll see changes, conflicts, and repository state

3. **Commands Available**
   - Most Git commands in Cursor will work with Jujutsu
   - The extension translates them to Jujutsu commands

### Workflow Considerations

#### Using Jujutsu with Existing Git Workflow

Since Jujutsu is Git-compatible:

- **Team members can continue using Git** - they won't notice you're using Jujutsu
- **Push/Pull works normally** - `jj git push` and `jj git pull` work with GitHub/GitLab
- **CI/CD systems work** - they see standard Git commits
- **GitHub/GitLab features work** - Pull requests, issues, etc. all function normally

#### Recommended Setup

1. **Keep Git commands available** - You can still use `git` commands if needed
2. **Use Jujutsu for local work** - Take advantage of Jujutsu's features locally
3. **Push via Jujutsu** - Use `jj git push` to sync with remote
4. **Team doesn't need to know** - Git users see standard Git commits

## GitHub/GitLab Integration

### No Separate Hosting Service Needed

**Key Point**: There is no Jujutsu-specific hosting service, and you don't need one. Jujutsu's Git compatibility means you can use:

- **GitHub** - Full compatibility
- **GitLab** - Full compatibility  
- **Bitbucket** - Full compatibility
- **Any Git hosting service** - Works with all of them

### How It Works

Jujutsu stores its data in Git repositories:

1. **Git objects** (commits, trees, blobs) are stored in standard Git format
2. **Jujutsu metadata** (Change IDs, operation log, bookmarks) is stored separately
3. **When you push**, Git objects go to GitHub/GitLab as normal Git commits
4. **Git users** see standard Git commits - they don't see Jujutsu-specific features

### Setting Up with GitHub

#### 1. Clone a GitHub Repository

```bash
# Clone using Jujutsu
jj git clone git@github.com:username/repository.git

# Or clone with HTTPS
jj git clone https://github.com/username/repository.git
```

#### 2. Configure SSH Keys (Recommended)

For seamless authentication:

```bash
# Generate SSH key if you don't have one
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add to GitHub
# Copy public key: cat ~/.ssh/id_ed25519.pub
# Add to GitHub: Settings → SSH and GPG keys → New SSH key
```

#### 3. Work with the Repository

```bash
# Create a change
jj new main -m "Add new feature"

# Make edits (automatically tracked)
# ... edit files ...

# Update commit message
jj describe -m "Updated: Add new feature with tests"

# Push to GitHub
jj branch set feature-branch
jj git push -b feature-branch
```

#### 4. Create Pull Request

- Go to GitHub in your browser
- You'll see your branch as normal
- Create a pull request as usual
- Git users can review and merge normally

### Setting Up with GitLab

Same process as GitHub:

```bash
# Clone GitLab repository
jj git clone git@gitlab.com:username/repository.git

# Work normally
jj new main -m "Add feature"
# ... edit files ...
jj branch set feature-branch
jj git push -b feature-branch
```

### Collaboration Workflow

#### Scenario: You Use Jujutsu, Team Uses Git

1. **You work locally with Jujutsu**
   - Use `jj` commands for all local operations
   - Take advantage of automatic rebasing, undo, etc.

2. **You push to GitHub/GitLab**
   - Use `jj git push -b branch-name`
   - Creates/updates a Git branch on remote

3. **Team members see normal Git**
   - They clone/pull as usual with `git`
   - They see standard Git commits
   - They can review PRs normally

4. **You pull their changes**
   - Use `jj git pull` or `jj git fetch`
   - Jujutsu imports their Git commits
   - You can continue using Jujutsu features

#### Benefits of This Approach

- **No team coordination needed** - Everyone can use their preferred tool
- **Gradual adoption** - You can try Jujutsu without forcing it on others
- **Full compatibility** - All Git features work (PRs, issues, CI/CD, etc.)
- **Easy rollback** - You can switch back to Git anytime

## Configuration for Your Dotfiles

### Cursor Settings

Add to `/Users/pete/dotfiles/cursor/settings.json`:

```json
{
  // Existing settings...
  "git.autofetch": true,
  
  // Jujutsu extension settings
  "jjk.jjPath": "jj",
  "jjk.enabled": true,
  "jjk.showStatusBar": true,
  
  // Optional: Prefer Jujutsu if available
  "scm.defaultViewMode": "tree"
}
```

### Git Configuration

Your existing Git config in `git/.gitconfig` will work fine. Jujutsu respects Git configuration for:
- User name/email
- Editor settings
- Credential helpers
- SSH keys

### Auto-Commit Watcher Compatibility

Your existing `autoCommitWatcher` setup should work, but you may want to:

1. **Update to use Jujutsu commands** (optional):
   ```json
   {
     "autoCommitWatcher.commitCommand": "jj commit -m",
     "autoCommitWatcher.statusCommand": "jj status"
   }
   ```

2. **Or keep using Git commands** - Since Jujutsu is Git-compatible, Git commands still work

### Recommended Workflow

For your dotfiles repository:

1. **Initialize Jujutsu** (if you want to try it):
   ```bash
   cd /Users/pete/dotfiles
   jj git init
   ```

2. **Use Jujutsu locally**:
   - Take advantage of automatic rebasing
   - Use undo for safety
   - Enjoy simpler workflow

3. **Push to GitHub normally**:
   ```bash
   jj git push -b main
   ```

4. **Keep Git as fallback**:
   - Git commands still work
   - Can switch back anytime

## Troubleshooting

### Extension Not Working

1. **Check Jujutsu Installation**:
   ```bash
   which jj
   jj --version
   ```

2. **Check Extension Settings**:
   - Verify `jjk.jjPath` is correct
   - Check that extension is enabled

3. **Reload Cursor**:
   - `Cmd+Shift+P` → "Developer: Reload Window"

### Git Compatibility Issues

If you encounter issues:

1. **Check Repository State**:
   ```bash
   jj status
   git status  # Should show same files
   ```

2. **Sync Bookmarks**:
   ```bash
   jj git sync
   ```

3. **Force Sync**:
   ```bash
   jj git push --all
   ```

### Performance Issues

For large repositories:

- Initialization may be slow
- Consider using Jujutsu only for new work
- Use Git for history-heavy operations

## Resources

- **Jujutsu Kaizen Extension**: https://github.com/keanemind/jjk
- **Jujutsu Documentation**: https://jj-vcs.github.io/jj/latest/
- **Jujutsu GitHub**: https://github.com/jj-vcs/jj
- **Cursor IDE**: https://cursor.sh/

## Summary

- **No separate hosting needed** - Use GitHub, GitLab, or any Git service
- **Cursor integration** - Install the "jjk" extension
- **Team compatibility** - Git users won't notice you're using Jujutsu
- **Gradual adoption** - Try it without disrupting your workflow
- **Full Git features** - PRs, issues, CI/CD all work normally

Jujutsu's Git compatibility is its killer feature - you get better local workflows while maintaining full compatibility with existing Git infrastructure and teams.



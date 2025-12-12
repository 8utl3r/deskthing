# Jujutsu VCS Research

## Overview

Jujutsu (abbreviated as `jj`) is a Git-compatible version control system written in Rust that reimagines traditional VCS workflows. It emphasizes changes over commits, automates many processes, and maintains full compatibility with Git repositories, allowing teams to adopt it incrementally without disrupting existing workflows.

## Key Features

- **Git-Compatible**: Works seamlessly with existing Git repositories
- **No Staging Area**: Working copy is treated as a commit, eliminating the need for `git add`
- **Change-Centric Model**: Tracks logical changes with stable Change IDs
- **Automatic Rebasing**: Descendant commits automatically rebase when ancestors are modified
- **First-Class Conflicts**: Conflicts are stored in commits and can be resolved later
- **Operation Log**: Every operation is recorded, enabling robust undo functionality
- **Anonymous Branches**: Flexible branching without requiring named branches

## Quick Reference

### Installation

```bash
# macOS
brew install jj

# Linux (Arch)
pacman -S jujutsu

# Or build from source
```

### Basic Commands

```bash
# Initialize a new repository
jj init

# Clone a Git repository
jj git clone <repository_url>

# Check status
jj status

# Create a new change
jj new

# Commit changes
jj commit -m "Your message"

# View log
jj log

# Undo last operation
jj undo
```

## Documentation Structure

- **[How It Works](how_it_works.md)** - Technical deep dive into architecture and concepts
- **[Comparison](comparison.md)** - Detailed comparison with Git and other VCS systems
- **[Usage Guide](usage_guide.md)** - Getting started, workflows, and migration from Git
- **[Cursor Integration](cursor_integration.md)** - Integrating Jujutsu with Cursor IDE and GitHub/GitLab
- **[Community Reception](community_reception.md)** - Reviews, adoption, and community feedback
- **[VCS Alternatives](vcs_alternatives.md)** - Overview of the version control landscape
- **[Complete Book](JUJUTSU_VCS_BOOK.md)** - Comprehensive guide in book format

## Why Jujutsu?

Jujutsu addresses several pain points in Git:

1. **Simplified Workflow**: No staging area means fewer steps to commit
2. **Better History Management**: Automatic rebasing and stable change IDs make history manipulation easier
3. **Conflict Handling**: Conflicts don't block your workflow - resolve them when convenient
4. **Safety Net**: Operation log provides undo for any action
5. **Git Compatibility**: Can be adopted incrementally without disrupting team workflows

## Current Status

- **GitHub**: ~1,200 stars, 150 forks (as of December 2025)
- **Status**: Early adoption, actively developed
- **Language**: Rust
- **License**: Apache 2.0

## Resources

- **Official Repository**: https://github.com/jj-vcs/jj
- **Documentation**: https://jj-vcs.github.io/jj/latest/
- **Tutorial**: https://jj-for-everyone.github.io/

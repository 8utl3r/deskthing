# Jujutsu vs Other Version Control Systems

## Jujutsu vs Git

### Key Differences

#### 1. Working Copy Model

**Git:**
- Working directory is separate from committed history
- Changes must be explicitly staged with `git add` before committing
- Three states: working directory, staging area (index), committed

**Jujutsu:**
- Working copy is treated as an implicit, always-present "working commit"
- Changes in the directory are automatically reflected in the current commit
- No separate staging area - eliminates the `git add` step

#### 2. Staging Area (Index)

**Git:**
- Utilizes a staging area (index) for preparing changes
- Allows partial commits (stage some files, leave others unstaged)
- Adds complexity: must remember to stage before committing

**Jujutsu:**
- No staging area
- Partial commits handled through powerful splitting and moving commands
- Simpler mental model: just edit and commit

#### 3. Change Model

**Git:**
- Focuses on commits as snapshots
- Each commit represents repository state at a point in time
- Commit IDs (SHA-1) change when commits are modified

**Jujutsu:**
- Emphasizes "changes" as first-class objects
- A "change" represents the evolution of a piece of work
- Stable "Change ID" persists across rewrites
- Commit ID changes when modified, but Change ID stays constant

#### 4. History Modification

**Git:**
- Requires manual rebasing of descendant commits when modifying earlier commits
- Must use `git rebase -i` or similar commands
- Can be error-prone and requires careful handling

**Jujutsu:**
- Automatically rebases all descendant commits when an earlier commit is modified
- No manual rebase commands needed
- Makes history editing much safer and easier

#### 5. Conflict Resolution

**Git:**
- Conflicts must be resolved immediately during merge/rebase operations
- Blocks workflow until conflicts are resolved
- Cannot commit with unresolved conflicts

**Jujutsu:**
- Conflicts are recorded in commits
- Can commit changes even with conflicts present
- Resolve conflicts at a convenient time
- Multiple commits can have conflicts simultaneously

#### 6. Undo Functionality

**Git:**
- Provides reflog for tracking changes
- Undoing operations can be complex
- Limited undo capabilities
- Must know specific commands to reverse actions

**Jujutsu:**
- Records every operation in an "operation log"
- `jj undo` works for any action
- Can step back through operation history
- Much more powerful and user-friendly

#### 7. Branching Model

**Git:**
- Uses named branches that point to specific commits
- Checking out a branch makes it the "current branch"
- New commits update the current branch
- Concept of "active" or "checked out" branch

**Jujutsu:**
- Uses "anonymous branches" by default (chains of commits without names)
- "Bookmarks" can name specific commits (map to Git branches)
- No concept of "current branch"
- More flexible: can work on multiple branches simultaneously

#### 8. Compatibility

**Git:**
- Standalone version control system
- Own workflows and commands
- Industry standard

**Jujutsu:**
- Git-compatible by design
- Can work with existing Git repositories
- Teams can mix Git and Jujutsu users
- Incremental adoption possible

### Workflow Comparison

**Git Workflow:**
```bash
git checkout -b feature
# edit files
git add file1.txt file2.txt
git commit -m "Add feature"
git push origin feature
```

**Jujutsu Workflow:**
```bash
jj new main
# edit files (automatically tracked)
jj commit -m "Add feature"
jj branch set feature
jj git push -b feature
```

## Jujutsu vs Mercurial

### Similarities

- Both emphasize user-friendly interfaces
- Both support distributed workflows
- Both have strong undo capabilities

### Differences

- **Mercurial**: More traditional branch-based model
- **Jujutsu**: Anonymous branches, change-centric model
- **Mercurial**: Separate staging area (though simpler than Git)
- **Jujutsu**: No staging area, working copy is a commit
- **Jujutsu**: Git compatibility (can use Git repos directly)
- **Mercurial**: Separate system, requires conversion

## Jujutsu vs Modern Alternatives

### Pijul

**Pijul:**
- Patch-based VCS using category theory
- Changes can be applied in any order (if independent)
- Mathematically sound conflict resolution
- No history rewriting needed

**Jujutsu:**
- Snapshot-based (like Git)
- Automatic rebasing when modifying history
- Git-compatible
- More familiar model for Git users

### Fossil

**Fossil:**
- Integrated project management (bug tracking, wiki)
- SQLite-based storage
- Simpler, all-in-one solution
- Less flexible than distributed systems

**Jujutsu:**
- Focused on version control
- More powerful VCS features
- Git-compatible
- Better for complex workflows

### Darcs

**Darcs:**
- Patch-based VCS
- Flexible patch application
- Performance issues with "exponential merge problem"
- Less actively developed

**Jujutsu:**
- Snapshot-based
- Better performance
- Actively developed
- Git-compatible

## Comparison Table

| Feature | Git | Jujutsu | Mercurial | Pijul | Fossil |
|-------|-----|---------|-----------|-------|--------|
| Staging Area | Yes | No | Yes | No | No |
| Git Compatible | N/A | Yes | No | No | No |
| Automatic Rebasing | No | Yes | No | N/A | No |
| First-Class Conflicts | No | Yes | No | Yes | No |
| Operation Log/Undo | Limited | Full | Good | Limited | Limited |
| Change IDs | No | Yes | No | Yes | No |
| Anonymous Branches | No | Yes | No | No | No |
| Performance (Large Repos) | Good | Variable | Good | Good | Good |
| Learning Curve | Steep | Moderate | Moderate | Steep | Easy |
| Community Size | Very Large | Small | Medium | Small | Small |

## When to Choose Jujutsu

### Good Fit For:

- Teams already using Git (incremental adoption)
- Developers frustrated with Git's complexity
- Projects requiring frequent history editing
- Workflows that benefit from automatic rebasing
- Teams wanting better conflict handling
- Developers who want undo for everything

### May Not Be Ideal For:

- Very large repositories (performance concerns)
- Teams requiring extensive GUI tooling (limited editor integration)
- Projects with strict Git-only requirements
- Teams uncomfortable with early-stage software

## Migration Considerations

### From Git to Jujutsu

**Advantages:**
- Can use existing Git repositories
- No need to convert history
- Team can mix Git and Jujutsu users
- Can switch back to Git anytime

**Process:**
- Simply run `jj git init` in existing Git repo
- Start using Jujutsu commands
- Git commands still work
- Bookmarks sync with Git branches automatically

### From Other VCS

- May require conversion through Git first
- Jujutsu's Git compatibility makes this easier
- Can use Git as an intermediate format

## Summary

Jujutsu offers a compelling alternative to Git by:
- Simplifying common workflows (no staging area)
- Providing better safety nets (operation log, undo)
- Making history editing easier (automatic rebasing)
- Maintaining Git compatibility (incremental adoption)

While adoption is still early, its Git compatibility and improved UX make it an attractive option for developers seeking a better version control experience without abandoning the Git ecosystem.

# How Jujutsu VCS Works

## Architecture Overview

Jujutsu is built with a modular, layered architecture:

### Core Components

1. **Core Library (`jj-lib`)**: Manages fundamental operations and data structures
2. **Storage Backends**: Handle persistence of repository data (supports multiple backends)
3. **User Interfaces (`jj-cli`)**: Command-line tools for user interaction

### Key Subsystems

- **Repository Management**: Uses `ReadonlyRepo`, `MutableRepo`, and `Transaction` for immutable views and transactional mutations
- **Operation Log**: Records all repository operations using `Operation`, `OpStore`, and `View` components
- **Working Copy**: Managed by `WorkingCopy` trait and `LocalWorkingCopy`, handles file system snapshots
- **Revision Sets (Revsets)**: Query language for selecting commits via `RevsetExpression` and `RevsetEngine`
- **Indexing**: Uses `CompositeIndex` and `ReadonlyIndex` for efficient commit graph traversal
- **Conflict Management**: Features `MergedTree` and `Merge<T>` for first-class conflict representation
- **Git Backend Integration**: `GitBackend` facilitates Git repository storage and synchronization

## Data Model

### Core Identifiers

Jujutsu introduces several unique identifier types:

#### CommitId
- Content-based identifier for a commit
- Changes when the commit is rewritten
- Similar to Git's SHA-1 hashes
- Immutable identifier representing a specific repository state

#### ChangeId
- Stable identifier for a logical change
- Persists across rewrites and amendments
- Allows tracking the evolution of changes over time
- Example: `oypoztxk` remains constant even when a commit is amended

**Key Distinction**: Modifying a commit changes its `CommitId` but retains the same `ChangeId`, facilitating tracking of logical changes.

#### TreeId
- Content-addressed identifier for tree (directory) objects
- Represents the state of a directory structure

#### FileId
- Content-addressed identifier for file content
- Represents the actual file data

#### SymlinkId
- Content-addressed identifier for symlink targets

#### CopyId
- Tracks copy/rename history
- Optionally content-addressed

## Working Copy Model

### Working Copy as a Commit

Jujutsu treats the working copy as a special commit. This fundamental design choice means:

- Any changes in the working directory are automatically recorded
- No separate staging area (index) is needed
- The working copy is always a valid commit state
- Commands like `jj status` show changes relative to the parent commit

### Automatic Snapshotting

Unlike Git's explicit staging process, Jujutsu automatically captures snapshots:
- Every command that modifies the working copy updates the working copy commit
- Changes are immediately available for operations like diff, log, etc.
- No need for `git add` - just edit files and commit

## Conflict Resolution

### First-Class Conflicts

Conflicts in Jujutsu are stored as first-class objects within commits:

- Conflicts are recorded as an ordered list of tree objects
- Can be committed even when conflicts exist
- Resolution can happen at a convenient time
- Multiple commits can have conflicts simultaneously

### Conflict Representation

Conflicts are represented using conflict markers in files:
- Similar to Git's conflict markers
- Can be edited directly in your editor
- Resolved conflicts are merged back into the commit

### Resolution Workflow

1. Create a new working-copy commit on top of the conflicted commit: `jj new <commit>`
2. Edit the conflicted files to resolve conflicts
3. Inspect changes with `jj diff`
4. Use `jj squash` to merge resolutions into the original conflicted commit

Alternatively, edit the conflicted commit directly with `jj edit <commit>`.

## Revision Sets (Revsets)

Revsets provide a functional query language for selecting commits:

### Basic Syntax

- `@` - The working copy commit
- `parents(x, 3)` - Select parents of commit x up to depth 3
- `descendants(x)` - All descendants of commit x
- `ancestors(x)` - All ancestors of commit x

### Use Cases

- Precise navigation through commit history
- Complex queries for commit manipulation
- Filtering commits based on various criteria
- Building custom workflows

## Git Integration

Jujutsu integrates with Git at two levels:

### Storage Layer

The `GitBackend` uses a Git repository for storing:
- Commit data (trees, blobs, commits)
- Standard Git objects

Jujutsu-specific metadata is stored separately in a `TableStore`:
- Change IDs
- Operation log
- Bookmarks
- Other Jujutsu-specific data

### Synchronization Layer

Bidirectional synchronization between Jujutsu and Git:

- **Import**: `import_refs()` - Maps Git branches/tags to Jujutsu bookmarks
- **Export**: `export_refs()` - Maps Jujutsu bookmarks to Git branches/tags
- Automatically triggered by most Jujutsu commands in colocated repositories

This design allows:
- Using Jujutsu with existing Git repositories
- Teams to mix Git and Jujutsu users
- Leveraging Git's mature storage and network protocols
- Extending Git with Jujutsu's features

## Operation Log

### Purpose

Every operation that modifies the repository is recorded in an operation log:
- Commits
- Pulls
- Merges
- Any repository mutation

### Undo Functionality

The operation log enables robust undo:

- `jj undo` - Undo the last operation
- `jj op log` - View operation history
- `jj op restore <operation_id>` - Restore to a specific operation state

### Benefits

- Safety net for any action
- Can step back through operations
- No need to remember exact commands to reverse actions
- Works for any operation, not just commits

## Automatic Rebasing

When you modify a commit, Jujutsu automatically:

1. Updates the modified commit (new CommitId, same ChangeId)
2. Rebases all descendant commits
3. Preserves the logical structure of changes
4. Handles conflicts by storing them in commits

This eliminates the need for manual rebase commands and makes history editing much safer and easier.

## Concurrency

Jujutsu is designed to handle concurrent operations safely:

- No reliance on lock files
- Multiple systems can access the repository simultaneously
- Prevents corruption in collaborative environments
- Improves performance in distributed workflows

## Performance Characteristics

### Strengths

- Snapshot-based architecture simplifies merging
- Concurrent access without locks
- Efficient conflict handling

### Limitations

- Initialization can be slow for very large repositories (millions of lines, hundreds of thousands of commits)
- Performance may vary with repository size

## Summary

Jujutsu's architecture prioritizes:
- **Simplicity**: Fewer concepts (no staging area, no active branch)
- **Safety**: Operation log and undo for everything
- **Flexibility**: Anonymous branches, first-class conflicts
- **Compatibility**: Full Git interoperability
- **Automation**: Automatic rebasing, automatic snapshotting

This design makes version control more intuitive while maintaining the power and flexibility developers need.

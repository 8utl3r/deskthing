# Dotfiles Maintenance Guide

## Version History
- 2026-01-31: Initial guide with backup strategy, incremental update process, and rules analysis.

## Overview

This guide covers dotfiles maintenance: incremental updates with verification, backup strategy, and rule refinements. Use it when updating configs, adding new tools, or reviewing organization.

---

## 1. Backup Strategy

### Current Built-in Backup

The `scripts/system/link` script already creates backups when applying symlinks:

- **Trigger**: When a real file (not symlink) exists at the destination
- **Action**: Moves existing file to `~/.dotfiles_backup_YYYYMMDD_HHMMSS/`
- **Scope**: Per-run; each `--apply` creates a new timestamped backup dir if conflicts exist

### Recommended: Pre-Update Backup

Before any significant update session, create a full backup:

```bash
# 1. Git commit current state (creates restore point)
cd ~/dotfiles && git add -A && git status
git commit -m "chore: snapshot before maintenance" || true

# 2. Tag for easy rollback (optional)
git tag -a "pre-maintenance-$(date +%Y%m%d)" -m "Before dotfiles maintenance"

# 3. Link script's built-in backup (when you run --apply)
./scripts/system/link --apply
```

### Rollback Options

| Scenario | Rollback Method |
|---------|-----------------|
| Bad symlink | `./scripts/system/link --apply` (re-run; backup already made) |
| Restore from backup dir | `cp ~/.dotfiles_backup_*/* /original/path/` |
| Revert last commit | `git reset --hard HEAD~1` |
| Restore from tag | `git checkout pre-maintenance-20260131` |

---

## 2. Incremental Update Process (One-by-One)

### Per-Component Checklist

For each config or tool you update:

1. **Backup** (if not already done this session)
   - `git add -A && git commit -m "chore: pre-update snapshot"` or ensure tag exists

2. **Update** one component
   - Edit the file in `~/dotfiles/` (e.g. `cursor/settings.json`)
   - Or add a new mapping to `scripts/system/link` if it's a new config

3. **Apply**
   - `./scripts/system/link --apply` (only if you changed link mappings)
   - Reload the app (e.g. Hammerspoon: Hyper+R, Cursor: restart, etc.)

4. **Verify**
   - Test the specific feature (shortcut, setting, behavior)
   - Check for errors (Hammerspoon Console, Cursor output, etc.)

5. **Commit**
   - `git add -p` (review changes) then `git commit -m "config: update [component]"`

6. **Next** component only after verification passes

### Verification Targets by Component

| Component | Verify By |
|-----------|-----------|
| Hammerspoon | Hyper+R reload, Console no errors, Hyper+T launches WezTerm |
| Karabiner | Profile switch, Caps Lock → Hyper |
| Cursor | Settings load, keybindings work |
| Shell | `source ~/.zshrc`, prompt renders, aliases work |
| Git | `git config --list` shows expected values |
| Starship | Prompt shows runtime info |
| Home Assistant | `ha-validate` passes, config loads |
| Alfred | Alfred opens, workflows respond |

---

## 3. Dotfiles Maintenance Research Summary

### Best Practices (from research)

- **Version control**: All configs in Git; tags for major restore points
- **Symlink manager**: Your `link` script is equivalent to Stow/chezmoi; keep it
- **Backup before migration**: Commit + tag before bulk changes
- **Incremental updates**: Update one component, verify, then proceed
- **Selective deployment**: Link script supports dry-run; use for new machines

### What to Back Up

- Shell configs (`.zshrc`, starship)
- Dev tools (git, cursor, mise)
- App configs (Alfred, Hammerspoon, Karabiner, etc.)
- Package lists (Brewfile, `scripts/system/snapshot`)

### Known Inconsistencies (Fix During Maintenance)

1. **Bootstrap path**: `scripts/system/bootstrap` calls `$REPO_ROOT/bin/link` but `bin/link` does not exist. Script lives at `scripts/system/link`. Fix: update bootstrap to use `scripts/system/link`.
2. **README vs reality**: README references `bin/link`, `bin/bootstrap`, `bin/snapshot`; actual scripts are in `scripts/system/`. Update README or add bin symlinks.
3. **Bootstrap REPO_ROOT**: When run as `./scripts/system/bootstrap`, `REPO_ROOT` becomes `scripts/` (one level up). Should be two levels up for repo root.

---

## 4. File Size Rule vs Qdrant

### Does Qdrant Care About File Size?

**No.** Qdrant (and vector DBs generally) chunk text before embedding:

- Embedding models have token limits (e.g. 512–8192 tokens)
- Your `index_wikipedia.py` uses `CHUNK_SIZE = 500` characters
- Large files are split into chunks; each chunk is embedded separately
- Original file size is irrelevant to retrieval quality

### Is the 200-Line Rule a Bad Idea?

**No.** The 200-line rule serves different goals than Qdrant:

| Concern | 200-Line Rule | Qdrant |
|---------|---------------|--------|
| Purpose | Human readability, AI context, micro-docs | Embedding model token limits |
| Applies to | Cursor/IDE context, human navigation | Vector search indexing |
| Chunking | N/A (file is loaded whole) | Automatic (500 chars, etc.) |

**When the 200-line rule helps:**

- **Cursor/agent context**: Loading a 500-line file uses more context tokens than a 200-line file
- **Human navigation**: Shorter files are easier to scan and edit
- **Micro-doc pattern**: One concept per file improves discoverability

**Recommendation**: Keep the 200-line rule for docs and config that agents or humans read directly. Relax or omit it for:

- Files only consumed by Qdrant (it chunks anyway)
- Machine-generated or rarely edited files
- Config files where splitting would hurt (e.g. one YAML with many keys)

---

## 5. Rules That May Need Rework

### Pre-Action Checklist (`docs/rules/pre_action_checklist.md`)

- **Issue**: Checklist Runs section has grown (7+ entries); file is 113 lines
- **Suggestion**: Archive old runs to `docs/archive/` or trim to last 2–3; add "see archive" note

### File Size Management Rule

- **Clarify scope**: Add note that rule applies to human/agent-consumed docs, not Qdrant-indexed content
- **Optional**: Add exception for "machine-only" or "indexed-only" files

### Bootstrap Script

- **Bug**: References non-existent `bin/link`; `REPO_ROOT` may be wrong when run from `scripts/system/`
- **Fix**: Use `"$(cd "$(dirname "$0")/../.." && pwd)"` for REPO_ROOT and `"$REPO_ROOT/scripts/system/link"` for the link script

### File Versioning Rule (in user rules)

- **Location**: Referenced in user rules but no `docs/rules/file_versioning_rule.md` found
- **Suggestion**: Create `docs/rules/file_versioning_rule.md` if you want it as a standalone rule

---

## 6. Maintenance Order Suggestion

Suggested order for one-by-one updates (safest first):

1. Fix `scripts/system/bootstrap` (path + REPO_ROOT)
2. Shell (`.zshrc`, starship) — easy to verify
3. Git config
4. Cursor (settings, keybindings)
5. Hammerspoon (init.lua, modules)
6. Karabiner
7. Home Assistant YAML
8. App plists (Alfred, ActiveDock, etc.)
9. README and wiki (align with actual script paths)

---

## 7. Quick Reference

- `./scripts/system/link` — dry-run; `--apply` to create symlinks (backs up conflicts)
- `./scripts/system/snapshot` — Brewfile + inventory
- `./scripts/system/update` — snapshot + commit
- `git tag -a "pre-maintenance-$(date +%Y%m%d)"` — restore point

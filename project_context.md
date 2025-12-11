# Project Context: Dotfiles

## Overview
Personal dotfiles repository for macOS system configuration and development environment setup. Focuses on reproducible, non-destructive configuration management.

## Architecture Summary
- **Configuration Management**: Symlink-based system with dry-run defaults and backup capabilities
- **Package Management**: Curated Brewfile with manual installation process
- **System Integration**: macOS defaults, Alfred workflows, Cursor IDE settings, ActiveDock 2
- **Shell Environment**: Zsh with Starship prompt, mise for runtime management
- **Window Management**: Hammerspoon and Karabiner for keyboard customization

## Current State
- Repository: `/Users/pete/dotfiles`
- Git Status: 17 commits ahead of origin/main
- Modified Files: `aerospace/aerospace.toml`, `hammerspoon/init.lua`, `karabiner/karabiner.json`
- Key Scripts: `scripts/system/link` (symlinks), `scripts/system/bootstrap` (setup), `scripts/system/snapshot` (inventory)

## Session Records

### 2025-01-06 - FlexiNet and Bloom Integration
- **Key Decisions**: Added FlexiNet and Bloom to dotfiles; fixed link script repo_root path calculation
- **Actions Taken**:
  - Added FlexiNet configuration structure (manually installed app)
  - Added Bloom configuration (already in Brewfile, now in dotfiles)
  - Created `flexinet/` and `bloom/` directories with README files
  - Added symlink mappings for both applications' preferences files
  - Copied existing Bloom preferences to dotfiles
  - Fixed `scripts/system/link` repo_root calculation (was going up one level too few)
- **Next 3 Specific Steps**:
  1. Configure FlexiNet to create preferences file, then symlink it
  2. Run `scripts/system/link --apply` to symlink Bloom configuration
  3. Test both applications' configurations are properly managed
- **Blockers/Concerns**: None - Bloom ready to symlink, FlexiNet waiting for preferences file

### 2025-01-06 - ActiveDock 2 Integration
- **Key Decisions**: Added ActiveDock 2 to dotfiles with full configuration support; configured to replace default macOS dock
- **Actions Taken**:
  - Added `cask "activedock"` to Brewfile (alphabetically ordered)
  - Installed ActiveDock 2 via Homebrew
  - Created `activedock/` directory structure
  - Added symlink mappings for Application Support directory and preferences plist
  - Created README documentation for ActiveDock 2 configuration
  - Hidden default macOS dock (autohide enabled with no delay)
  - Updated `macos/defaults.sh` with comment noting dock is hidden for ActiveDock 2
  - Created `scripts/system/configure-activedock` helper script
- **Next 3 Specific Steps**:
  1. Configure ActiveDock 2 preferences through the app (Settings menu)
  2. Run `scripts/system/link --apply` to symlink configuration files once preferences are created
  3. Customize ActiveDock 2 appearance and features as desired
- **Blockers/Concerns**: None - default dock is hidden, ActiveDock 2 is ready to use

See `session_records.md` for detailed session documentation.

## Next Steps
1. Install and configure ActiveDock 2
2. Test Ice menu bar configuration and functionality
3. Verify all rule compliance mechanisms are working

## Notes
- Repository follows lowercase naming convention with underscores
- All configuration files are symlinked from dotfiles to appropriate system locations
- Backup system preserves existing configurations before linking
- Files are kept under 200 lines with automatic splitting when exceeded
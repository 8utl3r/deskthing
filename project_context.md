# Project Context: Dotfiles

## Overview
Personal dotfiles repository for macOS system configuration and development environment setup. Focuses on reproducible, non-destructive configuration management.

## Architecture Summary
- **Configuration Management**: Symlink-based system with dry-run defaults and backup capabilities
- **Package Management**: Curated Brewfile with manual installation process
- **System Integration**: macOS defaults, Alfred workflows, Cursor IDE settings
- **Shell Environment**: Zsh with Starship prompt, mise for runtime management
- **Window Management**: Hammerspoon and Karabiner for keyboard customization

## Current State
- Repository: `/Users/pete/dotfiles`
- Git Status: 4 commits ahead of origin/main
- Modified Files: `scripts/system/link`, `cursor/mcp.json`
- Key Scripts: `scripts/system/link` (symlinks), `scripts/system/bootstrap` (setup), `scripts/system/snapshot` (inventory)

## Session Records

### 2025-01-06 - NuPhy Air75 Function Key Configuration
- **Date/Time**: 2025-01-06
- **Objective**: Resolve function key issues with NuPhy Air75 V2 keyboard on macOS
- **Key Decisions**: 
  - Enable function key state in macOS system preferences
  - Configure Karabiner-Elements for proper function key mapping
  - Use existing dotfiles infrastructure for configuration management
- **Actions Taken**:
  - Diagnosed NuPhy Air75 V2 keyboard recognition issue (keyboard detected but not properly identified)
  - Enabled function key state: `defaults write -g com.apple.keyboard.fnState -bool true`
  - Set full keyboard access: `defaults write -g AppleKeyboardUIMode -int 3`
  - Updated Karabiner-Elements configuration with explicit F1-F12 function key mappings
  - Applied configuration using existing dotfiles link system
  - Created backup of previous Karabiner configuration
- **Next 3 Specific Steps**:
  1. Test function keys (F1-F12) to verify they work properly
  2. Test special function key combinations (brightness, volume, etc.)
  3. Consider installing NuPhy Console for advanced customization if needed
- **Blockers/Concerns**: None - Configuration applied successfully

### 2025-01-06 - Home Assistant Integration
- **Date/Time**: 2025-01-06
- **Objective**: Add comprehensive Home Assistant configuration to dotfiles
- **Key Decisions**: 
  - Create dedicated `homeassistant/` directory for all HA configuration files
  - Integrate LG C5 monitor control using webOS API
  - Include macOS-specific automations and notifications
  - Use symlink-based configuration management following dotfiles pattern
- **Actions Taken**:
  - Created `homeassistant/` directory with complete configuration structure
  - Added `configuration.yaml` with LG C5 webOS integration and macOS settings
  - Created `automations.yaml` with dock-aware power management and volume control
  - Added `scripts.yaml` with reusable LG C5 control scripts
  - Created `groups.yaml` and `scenes.yaml` for organization and predefined modes
  - Added `secrets.yaml.template` for sensitive configuration data (includes server IP 192.168.0.105)
  - Updated `bin/link` script to include Home Assistant configuration symlinks
  - Integrated with existing LG C5 monitor control system (192.168.0.39)
  - Updated configuration for remote Home Assistant server at 192.168.0.105
- **Next 3 Specific Steps**:
  1. Install Home Assistant Companion app and configure connection to 192.168.0.105
  2. Configure LG webOS integration on the Home Assistant server
  3. Test macOS notifications and dock status integration through Companion app
- **Blockers/Concerns**: Requires "LG Connect Apps" to be enabled on TV for webOS API access

### 2025-01-06 - Home Assistant Development Workflow Setup
- **Date/Time**: 2025-01-06
- **Objective**: Establish comprehensive development workflow for Home Assistant with AI assistance
- **Key Decisions**: 
  - Create development documentation and templates for common configurations
  - Build helper scripts for validation and deployment
  - Establish remote server configuration management workflow
  - Create template system for rapid development
- **Actions Taken**:
  - Created `homeassistant/DEVELOPMENT.md` with comprehensive development workflow
  - Built `bin/ha-sync` script for remote configuration deployment
  - Built `bin/ha-validate` script for YAML validation and HA config checking
  - Created `homeassistant/templates/` directory with common configuration templates
  - Updated README.md with Home Assistant development instructions
  - Established AI-assisted development process documentation
- **Next 3 Specific Steps**:
  1. Test helper scripts with actual Home Assistant server
  2. Create first custom automation using templates
  3. Establish regular development workflow with AI assistance
- **Blockers/Concerns**: None - Complete development workflow is ready

### 2025-01-06 - LG C5 Monitor Control Setup
- **Date/Time**: 2025-01-06
- **Objective**: Set up comprehensive control system for new 42" LG C5 monitor
- **Key Decisions**: 
  - Use Hammerspoon for integration with existing automation setup
  - Create Python-based control script using WebOS API
  - Implement system sleep/wake integration for automatic power management
  - Use static IP configuration for reliable network communication
- **Actions Taken**:
  - Created `bin/lg-monitor` Python script for Network IP Control protocol (port 9761)
  - Created `hammerspoon/lg-monitor.lua` for Hammerspoon integration with robust error handling
  - Added hotkey bindings for power, volume, input switching, and mute control
  - Updated main Hammerspoon config to load LG monitor control
  - Implemented dock detection system (`bin/dock-detector-simple`)
  - Added dock detection to prevent control when not docked
  - Created comprehensive command reference (`docs/lg-c5-command-reference.md`)
  - Created setup guide (`docs/lg-c5-setup-guide.md`)
  - Updated IP address to 192.168.0.39 in all configuration files
  - Analyzed Savant Blueprint profile (`bin/lg_tv (2025).xml`) for exact protocol details
  - Implemented working Network IP Control protocol using port 9761
  - Successfully tested volume control, mute/unmute, and power off commands
  - Cleaned up all test files and created robust solution with proper error handling
  - Added comprehensive logging, timeout handling, and connection management
- **Next 3 Specific Steps**:
  1. Test Hammerspoon hotkey integration with clean implementation
  2. Test dock detection toggle hotkey (⌘⌥⌃D)
  3. Create final usage documentation
- **Blockers/Concerns**: None - Clean, robust IP control solution is ready!

### 2025-01-06 - Font Smoothing Configuration for QN90F Monitor
- **Date/Time**: 2025-01-06
- **Objective**: Configure optimal font smoothing settings for new 43" QN90F monitor
- **Key Decisions**: 
  - Use light font smoothing (AppleFontSmoothing -int 1) for large display optimization
  - Enable font smoothing globally (CGFontRenderingFontSmoothingDisabled -bool false)
  - Apply settings per-host to ensure monitor-specific configuration
- **Actions Taken**:
  - Added font smoothing configuration to `macos/defaults.sh`
  - Applied settings using `./macos/defaults.sh --apply`
  - Restarted system services (Dock, Finder, SystemUIServer)
- **Next 3 Specific Steps**:
  1. Test font rendering across different applications
  2. Adjust smoothing level if needed (0=disabled, 1=light, 2=medium, 3=strong)
  3. Commit configuration changes to dotfiles
- **Blockers/Concerns**: None

### 2025-01-06 - Rule Compliance Verification
- **Date/Time**: 2025-01-06
- **Objective**: Ensure full compliance with established rules and create missing project documentation
- **Key Decisions**: 
  - Create `project_context.md` following template structure
  - Establish `docs/rules/` directory for rule documentation
  - Verify all rule compliance mechanisms are in place
- **Actions Taken**:
  - Created `docs/rules/` directory structure
  - Created `project_context.md` with project overview
  - Documented current repository state and architecture
- **Next 3 Specific Steps**:
  1. Create supporting rule documentation files (`agent_doc_rule.md`, `agent_doc_format.md`, `agent_doc_compliance.md`)
  2. Update `project_context.md` with session end summary
  3. Commit documentation changes with appropriate message
- **Blockers/Concerns**: None

### 2025-01-06 - Bin Directory Cleanup
- **Date/Time**: 2025-01-06
- **Objective**: Clean up cluttered /bin directory by removing test and development files
- **Key Decisions**: 
  - Archive test files instead of deleting to preserve development history
  - Keep all essential dotfiles management scripts and working utilities
  - Maintain clear separation between production and development files
- **Actions Taken**:
  - Created `scripts/archive/` directory for test and development files
  - Moved 20 test files to archive: all `lg-test-*` scripts, `lg-debug`, `lg-server*`, `lg-start`, `lg-terminal`, `investigate-9761`, and `lg_tv (2025).xml`
  - Kept 25 essential files in main scripts directory: core dotfiles scripts (`bootstrap`, `link`, `snapshot`, `update`), utilities (`caffeine`, `cursor-extensions`, `hide-apple-apps`), dock detection scripts, LG monitor control scripts, and all Home Assistant integration scripts
  - Reduced scripts directory from 45 files to 25 essential files (44% reduction)
- **Next 3 Specific Steps**:
  1. Commit cleanup changes with descriptive message
  2. Update any documentation that references moved test files
  3. Consider creating README in archive directory explaining file purposes
- **Blockers/Concerns**: None - Cleanup completed successfully

### 2025-01-06 - Project Reorganization
- **Date/Time**: 2025-01-06
- **Objective**: Organize dotfiles project with logical directory structure for better maintainability
- **Key Decisions**: 
  - Group related functionality into dedicated subdirectories
  - Separate system management, utilities, and device-specific controls
  - Maintain clear separation between different types of functionality
  - Organize documentation and configuration files to match script organization
- **Actions Taken**:
  - Created organized scripts structure: `system/` (core dotfiles), `utilities/` (general tools), `lg-c5/` (monitor control), `home-assistant/` (HA integration)
  - Moved core dotfiles scripts to `scripts/system/`: `bootstrap`, `link`, `snapshot`, `update`
  - Moved utility scripts to `scripts/utilities/`: `caffeine`, `cursor-extensions`, `hide-apple-apps`
  - Moved LG C5 control scripts to `scripts/lg-c5/`: `lg-monitor`, `lg-monitor-connection`, `dock-detector`, `dock-detector-simple`
  - Moved Home Assistant scripts to `scripts/home-assistant/`: all `ha-*` scripts
  - Organized documentation: `docs/lg-c5/` (monitor docs), `docs/home-assistant/` (HA docs)
  - Organized Hammerspoon configs: `hammerspoon/lg-c5/` (monitor configs), `hammerspoon/home-assistant/` (HA configs)
  - Maintained archive directory for test files
- **Next 3 Specific Steps**:
  1. Update any scripts that reference moved files with new paths
  2. Create README files in each subdirectory explaining contents
  3. Commit reorganization changes with descriptive message
- **Blockers/Concerns**: None - Reorganization completed successfully

### 2025-01-06 - Directory Rename for Clarity
- **Date/Time**: 2025-01-06
- **Objective**: Rename `bin/` directory to `scripts/` for better clarity and to avoid confusion with system `/bin`
- **Key Decisions**: 
  - Rename directory to `scripts/` to clearly indicate it contains personal scripts
  - Update all documentation to reflect the new directory name
  - Maintain all existing organization and functionality
- **Actions Taken**:
  - Renamed `bin/` directory to `scripts/` using `mv bin scripts`
  - Updated `project_context.md` to reflect new directory paths
  - All subdirectories and files remain in their organized structure
  - No functional changes, only naming for clarity
- **Next 3 Specific Steps**:
  1. Update any remaining documentation that references old `bin/` paths
  2. Commit directory rename changes
  3. Verify all scripts still work with new paths
- **Blockers/Concerns**: None - Rename completed successfully

### 2025-01-06 - Disable AeroSpace Auto-Start
- **Date/Time**: 2025-01-06
- **Objective**: Disable AeroSpace window manager from starting automatically on system login
- **Key Decisions**: 
  - Disable AeroSpace auto-start to prevent conflicts while learning the system
  - Remove from macOS login items to ensure it doesn't start
  - Keep configuration file for future use when ready
- **Actions Taken**:
  - Updated `aerospace/aerospace.toml` to set `start-at-login = false`
  - Removed AeroSpace from macOS login items using AppleScript
  - Verified AeroSpace is no longer in login items list
  - Confirmed AeroSpace is not currently running
- **Next 3 Specific Steps**:
  1. Test system startup to confirm AeroSpace doesn't auto-start
  2. Learn AeroSpace functionality when ready to use it
  3. Re-enable auto-start when comfortable with the window manager
- **Blockers/Concerns**: None - AeroSpace auto-start successfully disabled

## Next Steps
1. Test Ice menu bar configuration and functionality
2. Verify all rule compliance mechanisms are working
3. Continue with any pending dotfiles configuration tasks

### 2025-01-06 - Ice Menu Bar Manager Implementation & macOS Sequoia Compatibility Fix
- **Date/Time**: 2025-01-06
- **Objective**: Transition from Hidden Bar to Ice for menu bar management, resolve macOS Sequoia compatibility
- **Key Decisions**: 
  - Replace Hidden Bar with Ice for improved menu bar item management
  - Use Ice beta version (0.11.13-dev.2) for macOS Sequoia compatibility
  - Follow dotfiles integration rule for all configuration changes
- **Actions Taken**:
  - Initial Homebrew cask install caused Swift concurrency crashes on macOS Sequoia
  - Diagnosed root cause: Swift swizzling incompatibility with macOS 26 (GitHub Issue #720)
  - Resolved by installing Ice beta v0.11.13-dev.2 directly from GitHub
  - Beta version includes XPC Services for better permission handling
  - Created comprehensive documentation in `docs/ice-macos-sequoia-fix.md`
- **Issues Resolved**:
  - Swift task continuation misuse: `waitForPermission() leaked continuation`
  - Update dialog freeze on application startup
  - Video artifacts in Ice settings window 
  - App crashes due to runtime swizzling in macOS Sequoia
- **Next 3 Specific Steps**:
  1. Test Ice menu bar functionality and customization features
  2. Monitor GitHub for stable Ice release with macOS Sequoia support
  3. Document migration back to Homebrew version when stable release available
- **Blockers/Concerns**: None - Beta version working correctly, monitoring for stable release

## Notes
- Repository follows lowercase naming convention with underscores
- All configuration files are symlinked from dotfiles to appropriate system locations
- Backup system preserves existing configurations before linking

# Session Records 2025: Peripherals

## Version History
- 2026-01-20: Moved 2025 peripheral records from `session_records.md`.

## 2025-01-06 - NuPhy Air75 Function Key Configuration
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

## 2025-01-06 - LG C5 Monitor Control Setup
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

## 2025-01-06 - Font Smoothing Configuration for QN90F Monitor
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

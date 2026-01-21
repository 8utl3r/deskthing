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

### 2025-01-20 - Copyparty Installation
- **Date/Time**: 2025-01-20
- **Key Decisions**: Installed copyparty via Homebrew for HTTP file sharing hub with WebDAV, SFTP, FTP, SMB support; complements Seafile for quick file sharing use cases
- **Actions Taken**:
  - Installed copyparty via Homebrew (version 1.20.2)
  - Added `brew "copyparty"` to Brewfile (alphabetically ordered after immich-cli)
  - Verified installation: `/opt/homebrew/bin/copyparty` available
  - Noted optional dependencies: ffmpeg for video/audio thumbnails, cfssl for CA/server-cert generation
- **Next 3 Specific Steps**:
  1. Create copyparty configuration file if needed (uses `-c PATH` flag for config files)
  2. Test copyparty server startup with basic configuration
  3. Configure volumes and accounts as needed for file sharing use cases
- **Blockers/Concerns**: None - copyparty is installed and ready to use; configuration is done via command-line options or config files; documented use cases already exist in `docs/copyparty-capabilities-analysis.md` and `docs/seafile-copyparty-together.md`

### 2025-01-06 - WiFiman Desktop Installation
- **Date/Time**: 2025-01-06
- **Key Decisions**: Added WiFiman Desktop to dotfiles for UniFi Teleport VPN client; documented via Homebrew Cask in Brewfile
- **Actions Taken**:
  - Added `cask "wifiman"` to Brewfile (alphabetically ordered before wezterm)
  - Created comprehensive `docs/unifi-teleport-macos.md` guide with installation, setup, and troubleshooting
  - Created `docs/ugreen-kvm-keyboard-issues.md` guide covering KVM keyboard problems and IPMI watchdog disable methods
  - Updated `docs/unifi-teleport-macos.md` to note Homebrew Cask installation method
  - Verified WiFiman Desktop is available via Homebrew Cask (version 1.2.8)
- **Next 3 Specific Steps**:
  1. Install WiFiman Desktop: `brew install --cask wifiman` (requires password for installer)
  2. Enable Teleport in UniFi Network: `Settings → VPN → Teleport` → On
  3. Generate invitation link and connect via WiFiman Desktop
- **Blockers/Concerns**: Installation requires sudo password (interactive prompt needed); WiFiman Desktop requires Cloud Gateway or Next-Gen Gateway for Teleport feature

### 2025-01-06 - Antinote Integration
- **Key Decisions**: Added Antinote to dotfiles with license key storage; configured for symlink management following existing app patterns
- **Actions Taken**:
  - Created `antinote/` directory structure in dotfiles
  - Created `antinote/README.md` with configuration documentation
  - Created `antinote/license-key.txt` with personal license key (GE9P-ZRN3-4ECW-ZWXZ)
  - Added symlink mapping to `scripts/system/link` for preferences plist file
  - Configured to symlink `com.antinote.Antinote.plist` once app is installed and configured
- **Next 3 Specific Steps**:
  1. Install Antinote from antinote.io
  2. Activate with license key GE9P-ZRN3-4ECW-ZWXZ
  3. Run `scripts/system/link --apply` to symlink preferences after first configuration
- **Blockers/Concerns**: None - Antinote structure is ready; bundle identifier may need verification after installation

### 2025-12-17 - Atlas Private Life Manager Implementation
- **Key Decisions**: Implemented Dolphin-Mistral-Nemo 12B as "Atlas" private life manager; configured for ADHD-friendly direct communication with 32k context window and low temperature (0.2) for reliable scheduling
- **Actions Taken**:
  - Added Ollama environment variables to `.zshrc`: `OLLAMA_KV_CACHE_TYPE=q8_0`, `OLLAMA_KEEP_ALIVE=24h`
  - Created modular `system_prompt.txt` with ADHD accommodations and direct communication style
  - Created `Modelfile.dolphin-mistral-nemo` with 32k context, temperature 0.2, and embedded system prompt
  - Downloaded Dolphin-2.9.3-Mistral-Nemo 12B Q6_K GGUF model (9.4GB) from HuggingFace
  - Created Atlas model in Ollama using custom Modelfile
  - Added shell aliases: `atlas` (run model), `atlas-prompt` (edit prompt), `atlas-reload` (reload model)
  - Updated `ollama/README.md` with comprehensive Atlas section
  - Updated `private_life_manager_architecture.md` with implementation status
  - Started Ollama service and verified model creation
- **Next 3 Specific Steps**:
  1. Test Atlas with real-life management tasks to verify behavior
  2. Iterate on system prompt based on usage patterns and feedback
  3. Monitor RAM usage during operation to ensure stability
- **Blockers/Concerns**: None - Atlas is fully configured and ready to use; model uses ~9-11GB RAM leaving adequate overhead; system prompt is modular for easy iteration

### 2025-01-06 - Ollama Installation and Setup
- **Key Decisions**: Added Ollama to dotfiles for local LLM management; installed both CLI and desktop GUI app via Homebrew, configured with shell aliases
- **Actions Taken**:
  - Added `brew "ollama"` to Brewfile (alphabetically ordered after mise)
  - Installed Ollama CLI via Homebrew (version 0.13.4)
  - Added `cask "ollama-app"` to Brewfile (alphabetically ordered after netspot)
  - Installed Ollama desktop GUI app via Homebrew (version 0.13.4)
  - Created `ollama/` directory in dotfiles with comprehensive README documentation
  - Added useful shell aliases to `.zshrc`: `ollama-list`, `ollama-ps`, `ollama-pull`
  - Documented common commands, popular models, API usage, environment variables, and GUI app features
  - Updated wiki/Development-Tools.md with Ollama section including GUI app details
  - Verified no separate config files needed (app uses same backend service as CLI)
- **Next 3 Specific Steps**:
  1. Start Ollama service: `brew services start ollama`
  2. Pull a test model: `ollama pull llama3.2` or use GUI app
  3. Test both CLI and GUI interfaces to verify installation
- **Blockers/Concerns**: None - Both Ollama CLI and desktop GUI app are installed and ready to use; service needs to be started before first use; app available in Applications folder

### 2025-01-06 - Hammerflow Integration
- **Key Decisions**: Added Hammerflow leader key system to Hammerspoon setup; configured with F18 as leader key
- **Actions Taken**:
  - Cloned Hammerflow repository from GitHub (saml-dev/hammerflow)
  - Moved to proper Spoon structure: `hammerspoon/Spoons/Hammerflow.spoon/`
  - Integrated Hammerflow into `init.lua` with auto-reload support
  - Created `hammerflow.toml` configuration with app launchers, window management, and Hammerspoon config shortcuts
  - Updated Hammerspoon README documentation to include Hammerflow
- **Next 3 Specific Steps**:
  1. Configure Karabiner to remap Right Command to F18 for dedicated leader key
  2. Customize `hammerflow.toml` with additional shortcuts and groups as needed
  3. Test Hammerflow leader key sequences and verify all shortcuts work
- **Blockers/Concerns**: None - Hammerflow is integrated and ready to use; recommend setting up F18 remap in Karabiner for optimal experience

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

### 2025-01-20 - n8n Setup on TrueNAS Scale NAS
- **Key Decisions**: Installed n8n on TrueNAS Scale 25.04.2.6 NAS (Ugreen DXP2800) as production instance; removed local MacBook setup
- **Actions Taken**:
  - Installed n8n app via TrueNAS Apps (community train)
  - Configured storage mounts: Host Path `/mnt/tank/apps/n8n` for n8n data, `/mnt/tank/apps/n8n-postgres` for PostgreSQL
  - Fixed permissions: set `/mnt/tank/apps/n8n` ownership to `apps:apps` (UID/GID 568) via `midclt call filesystem.chown`
  - Started n8n app successfully; verified running at `http://192.168.0.158:30109`
  - Removed local MacBook setup: deleted `~/.n8n` directory and `docker-compose.yml`
  - Updated dotfiles documentation to reflect NAS instance only
- **Next 3 Specific Steps**:
  1. Access n8n web interface at `http://192.168.0.158:30109` and complete setup wizard
  2. Import workflows from `n8n/workflows/` directory to NAS instance
  3. Configure n8n settings and create first workflows
- **Blockers/Concerns**: None - n8n is running on NAS and ready to use

See `session_records.md` for detailed session documentation.

## Next Steps
1. Start Ollama service and test with a model
2. Install and configure ActiveDock 2
3. Test Ice menu bar configuration and functionality

## Notes
- Repository follows lowercase naming convention with underscores
- All configuration files are symlinked from dotfiles to appropriate system locations
- Backup system preserves existing configurations before linking
- Files are kept under 200 lines with automatic splitting when exceeded
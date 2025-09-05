# Pete's Dotfiles Wiki

Welcome to the comprehensive manual for Pete's macOS dotfiles setup. This wiki provides detailed usage instructions for every component managed by the dotfiles.

## 📋 Table of Contents

### Core Components
- [Shell & Terminal](Shell-and-Terminal) - Zsh, Starship, WezTerm, mise
- [Development Tools](Development-Tools) - Git, GitHub CLI, Docker, CLI utilities
- [Window Management](Window-Management) - AeroSpace, Karabiner-Elements, Hammerspoon
- [Applications](Applications) - Alfred, Cursor, and all managed applications
- [System Configuration](System-Configuration) - macOS defaults and system tweaks

### Reference
- [Troubleshooting](Troubleshooting) - Common issues and solutions
- [Configuration Files](Configuration-Files) - Complete file reference
- [Scripts Reference](Scripts-Reference) - All automation scripts

## 🚀 Quick Start

```bash
# Link all configuration files
./bin/link --apply

# Apply macOS system defaults
./macos/defaults.sh --apply

# Install all applications
brew bundle --file ./Brewfile
```

## 🎯 Philosophy

This dotfiles setup follows these principles:

- **Reproducible**: Everything can be recreated from scratch
- **Non-destructive**: Dry-run by default, backups before changes
- **Cloud-synced**: Prefers cloud sync over local config when possible
- **Power-user focused**: Optimized for efficiency and productivity
- **Well-documented**: Every component has clear usage instructions

## 🔧 Key Features

- **Hyper Key**: Caps Lock becomes cmd+opt+ctrl+shift when held, Escape when tapped
- **Tiling Windows**: AeroSpace provides i3-like window management
- **Smart Aliases**: `cat` → `bat`, `ls` → `eza` with fallbacks
- **Runtime Management**: mise handles Node.js, Python, Java, Rust versions
- **Git UX**: Delta pager, aliases, commit templates
- **macOS Tweaks**: Power-user defaults for Finder, Dock, keyboard, etc.

## 📁 Project Location

**Absolute Path**: `/Users/pete/dotfiles`

## 📁 Project Structure

```
dotfiles/
├── bin/                    # Automation scripts
├── shell/                  # Shell configuration
├── git/                    # Git configuration
├── cursor/                 # Cursor IDE settings
├── docker/                 # Docker configuration
├── aerospace/              # Window manager config
├── karabiner/              # Keyboard customization
├── hammerspoon/            # Automation scripts
├── alfred/                 # Application launcher
├── macos/                  # macOS system defaults
├── runtimes/               # Runtime manager config
├── terminal/               # Terminal configuration
└── Brewfile               # Homebrew package list
```

## 🆘 Getting Help

- Check the [Troubleshooting](Troubleshooting) page for common issues
- Review individual component pages for detailed usage
- All scripts support `--help` or `--dry-run` for safe testing

---

**Last Updated**: September 2024  
**Version**: Complete setup with 26 applications and comprehensive configuration

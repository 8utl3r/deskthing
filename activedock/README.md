# ActiveDock 2 Configuration

This directory contains ActiveDock 2 configuration files that are symlinked to system locations.

## Files

- `com.sergey-gerasimenko.ActiveDock-2/` - Application Support directory (symlinked to `~/Library/Application Support/com.sergey-gerasimenko.ActiveDock-2`)
- `com.sergey-gerasimenko.ActiveDock-2.plist` - Preferences file (symlinked to `~/Library/Preferences/com.sergey-gerasimenko.ActiveDock-2.plist`)
- `CONFIGURE_DEFAULT_APPEARANCE.md` - Guide for configuring ActiveDock 2 to match default macOS dock

## Installation

ActiveDock 2 is installed via Homebrew Cask (see `Brewfile`).

## Configuration

### Quick Setup

1. **Configure Appearance**: See `CONFIGURE_DEFAULT_APPEARANCE.md` for detailed instructions on making ActiveDock 2 look like the default macOS dock.

2. **Symlink Configuration**: After configuring ActiveDock 2, run:
   ```bash
   scripts/system/link --apply
   ```

### Helper Scripts

- `scripts/system/configure-activedock` - Hides default dock and sets up ActiveDock 2
- `scripts/system/configure-activedock-appearance` - Configures ActiveDock 2 to match default dock appearance (run after creating preferences file)


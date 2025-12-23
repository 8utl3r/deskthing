# Antinote Configuration

This directory contains Antinote (temporary notes and quick calculations app) configuration files that are symlinked to system locations.

## License Key

Personal license key: `GE9P-ZRN3-4ECW-ZWXZ`

The license key is stored in `license-key.txt` for reference. After installing Antinote, enter this key in the app's activation dialog.

## Files

Configuration files will be symlinked once Antinote is installed and configured:

- `com.antinote.Antinote.plist` - Preferences file (symlinked to `~/Library/Preferences/com.antinote.Antinote.plist`)
- Application Support directory (if needed)

## Installation

Antinote can be installed manually from [antinote.io](https://antinote.io/).

## Configuration

After installing and activating Antinote with the license key, run the symlink script to manage your settings in dotfiles:

```bash
scripts/system/link --apply
```

This will symlink:
- `~/Library/Preferences/com.antinote.Antinote.plist` → `dotfiles/antinote/com.antinote.Antinote.plist`

## Bundle Identifier

- `com.antinote.Antinote` (estimated - verify after installation)

## Notes

- License key is stored in `license-key.txt` for reference
- Configuration files will be created automatically after first launch and configuration
- Once preferences are created, they will be symlinked to this directory


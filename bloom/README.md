# Bloom Configuration

This directory contains Bloom (advanced Finder replacement) configuration files that are symlinked to system locations.

## Files

- `com.asiafu.Bloom.plist` - Preferences file (symlinked to `~/Library/Preferences/com.asiafu.Bloom.plist`)

## Installation

Bloom is installed via Homebrew Cask (see `Brewfile`).

## Configuration

Bloom preferences include:
- Window size and layout settings
- Keyboard shortcuts
- View options for different directories
- Toolbar configurations

After configuring Bloom, run the symlink script to manage your settings in dotfiles:

```bash
scripts/system/link --apply
```

This will symlink:
- `~/Library/Preferences/com.asiafu.Bloom.plist` → `dotfiles/bloom/com.asiafu.Bloom.plist`

## Bundle Identifier

- `com.asiafu.Bloom`




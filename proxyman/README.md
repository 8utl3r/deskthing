# Proxyman Configuration

This directory contains Proxyman configuration files that can be symlinked to system locations.

## Files

- `com.proxyman.NSProxy.plist` - Preferences file (symlinked to `~/Library/Preferences/com.proxyman.NSProxy.plist`)

## Installation

Proxyman is installed via Homebrew Cask (see `Brewfile`).

## Configuration

1. Launch Proxyman at least once so macOS creates the preferences file.
2. Copy your preferences into this folder:

```bash
cp ~/Library/Preferences/com.proxyman.NSProxy.plist ~/dotfiles/proxyman/
```

3. Re-run dotfiles linking:

```bash
scripts/system/link --apply
```

This will symlink:

- `~/Library/Preferences/com.proxyman.NSProxy.plist` -> `~/dotfiles/proxyman/com.proxyman.NSProxy.plist`

## Bundle Identifier

- `com.proxyman.NSProxy`

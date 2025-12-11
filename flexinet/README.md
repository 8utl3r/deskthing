# FlexiNet Configuration

This directory contains FlexiNet configuration files that are symlinked to system locations.

## Files

- `com.macplus-software.FlexiNet.plist` - Preferences file (symlinked to `~/Library/Preferences/com.macplus-software.FlexiNet.plist`)

## Installation

FlexiNet is installed manually (not via Homebrew).

## Configuration

After configuring FlexiNet, run the symlink script to manage your settings in dotfiles:

```bash
scripts/system/link --apply
```

This will symlink:
- `~/Library/Preferences/com.macplus-software.FlexiNet.plist` → `dotfiles/flexinet/com.macplus-software.FlexiNet.plist`

## Bundle Identifier

- `com.macplus-software.FlexiNet`




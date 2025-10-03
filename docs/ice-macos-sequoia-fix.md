# Ice macOS Sequoia Compatibility Fix

## Problem Summary

Ice v0.11.12 crashes on macOS Sequoia (v26.0) with Swift task continuation misuse errors:

```
SWIFT TASK CONTINUATION MISUSE: waitForPermission() leaked its continuation without resuming it.
```

This causes:
- App crashes on startup
- Update dialog freeze
- Video artifacts in menu bar settings

## Root Cause

From GitHub Issue #720: **Swizzling incompatibility with macOS 26+**

The Ice app uses runtime method swizzling (hooking into NSStatusBarWindow methods) that breaks in macOS Sequoia's new runtime system.

## Solution

**Use Ice v0.11.13-dev.2 (beta version)**

This version includes:
- ✅ **XPC Services** for better permission handling
- ✅ **macOS Sequoia compatibility**  
- ✅ **Fixed Swift concurrency** issues
- ✅ **No crash reports**

## Installation Method

Direct GitHub download instead of Homebrew cask:

```bash
cd ~/Downloads
curl -L -o Ice-beta.dmg "https://github.com/jordanbaird/Ice/releases/download/0.11.13-dev.2/Ice.zip"
unzip Ice-beta.dmg
cp -R Ice.app /Applications/
```

## GitHub References

- **Issue #720**: "fix: Disable swizzling for macOS 26 and above" (not yet merged)
- **Issue #723**: "Icons don't stay at its place - they flip after restart (Sequoia & Tahoe)"

## Dotfiles Integration

- `ice/com.jordanbaird.Ice.plist` - Configuration symlinked via `scripts/system/link`
- `README.md` - Updated to reference Ice menu bar manager
- `Brewfile` - Commented out cask, using direct GitHub download

Last Updated: 2025-01-06

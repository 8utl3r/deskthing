# dotfiles

Reproducible, non-destructive macOS setup. Installs are manual by design.

Contents:
- `bin/link`: symlink repo configs into `$HOME` (dry-run by default)
- `bin/bootstrap`: run symlinks; leaves installs to you
- `macos/defaults.sh`: optional macOS defaults (DRY-RUN unless `--apply`)
- `Brewfile`: curated apps/tools (run with `brew bundle` manually)
 - `aerospace/aerospace.toml`: tiling window manager config (linked to `~/.aerospace.toml`)
 - `cursor/keybindings.json`: extra Cursor keybindings (linked to Cursor User dir)
 - `git/.gitmessage`: commit template (linked to `~/.gitmessage`)
 - `karabiner/karabiner.json`: Karabiner-Elements config (linked to `~/.config/karabiner/karabiner.json`)
 - `hammerspoon/init.lua`: Hammerspoon config (linked to `~/.hammerspoon/init.lua`)
 - `alfred/Alfred.alfredpreferences`: optional Alfred prefs (linked to Alfred support dir)

Quick start:
```bash
# Preview what will be linked
~/dotfiles/bin/link --dry-run

# Create/overwrite symlinks (backs up real files to ~/.dotfiles_backup_*)
~/dotfiles/bin/link --apply
```

Optional:
```bash
# Apply macOS defaults (idempotent)
~/dotfiles/macos/defaults.sh --apply

# Update Brewfile and inventory snapshot
~/dotfiles/bin/snapshot
```
New defaults include: Finder cleanliness (no warnings, text selection), Dock hot corners off, screenshot folder and PNG, expanded save/print panels, local-save default, battery percent, natural scroll, prevent Photos auto-open. All are user-level and reversible by UI.

Manual installs:
```bash
# Inspect, then install from curated list
brew bundle --file ~/dotfiles/Brewfile
```

Tip: `git-delta` is included; run `brew bundle` to enable the improved pager.

Optional (AeroSpace):
```bash
# Install AeroSpace (from tap in Brewfile)
brew install --cask nikitabobko/tap/aerospace

# Reload AeroSpace after linking config
osascript -e 'tell application "AeroSpace" to quit' 2>/dev/null || true
open -a AeroSpace
```

Optional (Karabiner/Hammerspoon):
```bash
# Install
brew install --cask karabiner-elements hammerspoon

# After linking config
open -a "Karabiner-Elements"
open -a Hammerspoon
```

Optional (Alfred Sync):
```bash
# After linking, in Alfred Preferences → Advanced → Set preferences folder
# choose: ~/dotfiles/alfred/Alfred.alfredpreferences
# Note: license and caches are gitignored; do not commit your license.
```

Notes:
- Git identity in `git/.gitconfig` is a placeholder; set your name/email.
- Cursor settings live at `cursor/settings.json` and are linked by `bin/link`.
  Keybindings live at `cursor/keybindings.json`.
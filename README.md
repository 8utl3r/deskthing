# dotfiles

Reproducible, non-destructive macOS setup. Installs are manual by design.

Contents:
- `bin/link`: symlink repo configs into `$HOME` (dry-run by default)
- `bin/bootstrap`: run symlinks; leaves installs to you
- `macos/defaults.sh`: optional macOS defaults (DRY-RUN unless `--apply`)
- `Brewfile`: curated apps/tools (run with `brew bundle` manually)
 - `aerospace/aerospace.toml`: tiling window manager config (linked to `~/.aerospace.toml`)
 - `cursor/keybindings.json`: extra Cursor keybindings (linked to Cursor User dir)

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

Manual installs:
```bash
# Inspect, then install from curated list
brew bundle --file ~/dotfiles/Brewfile
```

Optional (AeroSpace):
```bash
# Install AeroSpace (from tap in Brewfile)
brew install --cask nikitabobko/tap/aerospace

# Reload AeroSpace after linking config
osascript -e 'tell application "AeroSpace" to quit' 2>/dev/null || true
open -a AeroSpace
```

Notes:
- Git identity in `git/.gitconfig` is a placeholder; set your name/email.
- Cursor settings live at `cursor/settings.json` and are linked by `bin/link`.
  Keybindings live at `cursor/keybindings.json`.
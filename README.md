# dotfiles

A reproducible, non-destructive setup. No installs by default.

- bin/link: creates symlinks to home directory (dry-run by default)
- bin/bootstrap: convenience wrapper (does not install apps)
- macos/defaults.sh: optional macOS settings (not executed automatically)

Usage:
  # preview symlinks
  ~/dotfiles/bin/link --dry-run

  # apply symlinks
  ~/dotfiles/bin/link --apply


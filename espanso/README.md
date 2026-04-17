# Espanso Configuration

This directory contains Espanso (text expander) configuration, symlinked to `~/Library/Application Support/espanso`.

## Files

- `config/default.yml` — default Espanso options
- `match/base.yml` — snippet definitions (triggers and replacements)

## Installation

Espanso is installed via Homebrew Cask (see repo root `Brewfile`). After installing, open Espanso once and grant **Accessibility** in System Settings → Privacy & Security so it can inject text.

## Symlink

Apply symlinks from the repo root:
```bash
scripts/system/link --apply
```

## Useful commands

- `espanso path` — print config directory path
- `espanso edit` — edit match/base.yml with default editor
- `espanso status` — show if Espanso is running

See [Espanso docs](https://espanso.org/docs/) and [Typinator replacement decision matrix](docs/archive/typinator-foss-replacement-decision-matrix.md).

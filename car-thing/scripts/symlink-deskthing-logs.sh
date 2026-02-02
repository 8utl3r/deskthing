#!/usr/bin/env bash
# Migrate DeskThing logs to dotfiles and symlink. Run once; quit DeskThing first.
# Usage: ./car-thing/scripts/symlink-deskthing-logs.sh

set -e

DESKTHING_LOGS="$HOME/Library/Application Support/deskthing/logs"
DOTFILES_LOGS="$(cd "$(dirname "$0")/../deskthing-logs" && pwd)"

if [[ ! -d "$DESKTHING_LOGS" ]]; then
  echo "DeskThing logs folder not found: $DESKTHING_LOGS"
  exit 1
fi

if [[ -L "$DESKTHING_LOGS" ]]; then
  echo "Logs already symlinked to dotfiles."
  ls -la "$DESKTHING_LOGS"
  exit 0
fi

echo "Copying logs to dotfiles..."
cp -a "$DESKTHING_LOGS"/* "$DOTFILES_LOGS/" 2>/dev/null || true

echo "Running link script to create symlink..."
"$(cd "$(dirname "$0")/../.." && pwd)/scripts/system/link" --apply

echo "Done. DeskThing logs now at: $DOTFILES_LOGS"
echo "View latest: tail -f $DOTFILES_LOGS/application.log.json"

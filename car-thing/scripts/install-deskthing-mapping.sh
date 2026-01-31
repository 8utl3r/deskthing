#!/usr/bin/env bash
# Install our full hardware mapping as DeskThing's default profile.
# Run from repo root. Quit DeskThing before running.

set -e

DESKTHING_USER_DATA="${DESKTHING_USER_DATA:-$HOME/Library/Application Support/DeskThing}"
CAR_THING_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MAPPING_SRC="$CAR_THING_DIR/config/deskthing-default-mapping.json"
MAPPINGS_DIR="$DESKTHING_USER_DATA/mappings"
DEFAULT_JSON="$MAPPINGS_DIR/default.json"
BACKUP_DIR="$MAPPINGS_DIR.backup.$(date +%Y%m%d-%H%M%S)"

if [[ ! -f "$MAPPING_SRC" ]]; then
  echo "Not found: $MAPPING_SRC (run from repo root)" >&2
  exit 1
fi

if pgrep -x DeskThing >/dev/null 2>&1; then
  echo "DeskThing appears to be running. Quit it first, then run this script again." >&2
  exit 1
fi

if [[ -d "$MAPPINGS_DIR" ]]; then
  echo "Backing up $MAPPINGS_DIR to $BACKUP_DIR"
  cp -R "$MAPPINGS_DIR" "$BACKUP_DIR"
fi

mkdir -p "$MAPPINGS_DIR"
cp "$MAPPING_SRC" "$DEFAULT_JSON"
echo "Installed: $DEFAULT_JSON"
echo "Start DeskThing and use the Default profile."

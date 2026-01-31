#!/usr/bin/env bash
# Push DeskThing app to Car Thing via CLI.
# Builds the app, then either:
#   - Copies to DeskThing's apps folder (requires DeskThing restart to pick up)
#   - Or opens the dist folder for manual Upload App in DeskThing GUI.
#
# Usage: ./scripts/push.sh [--install|--open]
#   --install  Copy to DeskThing apps dir (experimental; restart DeskThing after)
#   --open     Build and open dist folder in Finder (default)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/../deskthing-app" && pwd)"
DIST_DIR="$APP_DIR/dist"

# DeskThing userData on macOS
DESKTHING_APPS="${HOME}/Library/Application Support/deskthing/apps"
APP_ID="deskthingapp"

cd "$APP_DIR"
echo "Building app..."
npm run build

if [[ "$1" == "--install" ]]; then
  APP_DEST="$DESKTHING_APPS/$APP_ID"
  mkdir -p "$APP_DEST"
  echo "Installing to $APP_DEST..."
  # Copy built app structure (exclude zip, latest.json)
  rsync -a --delete \
    --exclude='*.zip' \
    --exclude='latest.json' \
    "$DIST_DIR/" "$APP_DEST/"
  echo "Done. Restart DeskThing to pick up the app."
elif [[ "$1" == "--open" ]] || [[ -z "$1" ]]; then
  open "$DIST_DIR"
  echo "Opened dist folder. Upload the .zip via DeskThing → Downloads → Upload App."
else
  echo "Usage: $0 [--install|--open]"
  echo "  --install  Copy to DeskThing apps (restart DeskThing after)"
  echo "  --open     Build and open dist folder (default)"
  exit 1
fi

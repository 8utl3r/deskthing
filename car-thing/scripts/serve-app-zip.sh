#!/usr/bin/env bash
# Build the app from the repo and serve the .zip on HTTP so you can download
# "latest" and Upload App in DeskThing. Source of truth = our git (current tree).
# Usage: ./car-thing/scripts/serve-app-zip.sh [port]
# Default port 8766. Download: http://localhost:8766/<zipname>

set -e

CAR_THING_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$CAR_THING_DIR/deskthing-app"
DIST_DIR="$APP_DIR/dist"
PORT="${1:-8766}"

cd "$APP_DIR"
echo "Building app from repo..."
npm run build

ZIP=( "$DIST_DIR"/*.zip )
if [[ ! -f "${ZIP[0]:-}" ]]; then
  echo "No .zip in dist. Build may not produce a zip; check deskthing-app build." >&2
  exit 1
fi

echo "Serving $DIST_DIR on port $PORT"
echo "Download zip from: http://localhost:$PORT/$(basename "${ZIP[0]}")"
echo "Then DeskThing → Downloads → Upload App → select that file (or open URL in browser and save)."
cd "$DIST_DIR"
exec python3 -m http.server "$PORT"

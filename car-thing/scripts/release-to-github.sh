#!/usr/bin/env bash
# Build the app and create a GitHub Release with the .zip asset.
# Requires: gh CLI, and a public repo (set GITHUB_REPO or pass as first arg).
# Usage: ./car-thing/scripts/release-to-github.sh [owner/repo] [tag]
# Example: ./car-thing/scripts/release-to-github.sh 8utl3r/deskthing v0.11.1
# If tag is omitted, uses version from package.json (e.g. v0.11.1).

set -e

CAR_THING_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$CAR_THING_DIR/deskthing-app"
DIST_DIR="$APP_DIR/dist"

REPO="${1:-${GITHUB_REPO}}"
TAG="${2:-}"

if [[ -z "$REPO" ]]; then
  echo "Usage: $0 [owner/repo] [tag]" >&2
  echo "  or set GITHUB_REPO (e.g. 8utl3r/deskthing)" >&2
  exit 1
fi

cd "$APP_DIR"
VERSION="$(node -p "require('./package.json').version")"
TAG="${TAG:-v$VERSION}"

echo "Building app..."
npm run build

ZIP=( "$DIST_DIR"/*.zip )
if [[ ! -f "${ZIP[0]:-}" ]]; then
  echo "No .zip in dist. Build may not produce a zip." >&2
  exit 1
fi

echo "Creating release $TAG in $REPO with $(basename "${ZIP[0]}")..."
gh release create "$TAG" "${ZIP[@]}" --repo "$REPO" --notes "Release $TAG"
echo "Done. Update manifest repository/updateUrl to https://github.com/$REPO if not already set."

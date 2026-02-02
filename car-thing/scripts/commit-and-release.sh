#!/usr/bin/env bash
# Commit car-thing changes, push to origin, sync to public repo, and create GitHub release.
# Run after making changes to car-thing or the Hammerspoon bridge.
#
# Usage: ./car-thing/scripts/commit-and-release.sh [commit-message]
#   If message omitted, uses "car-thing: <version> - <timestamp>"
#
# Requires: gh CLI, git, npm. Remotes: origin (dotfiles), deskthing (8utl3r/deskthing).

set -e

CAR_THING_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DOTFILES_ROOT="$(cd "$CAR_THING_DIR/.." && pwd)"
REPO="${GITHUB_REPO:-8utl3r/deskthing}"

# Paths to stage (car-thing app, bridge, config, docs)
PATHS=(
  "car-thing/"
  "hammerspoon/modules/car-thing-bridge.lua"
)

cd "$DOTFILES_ROOT"

# Check for changes in our paths
CHANGED=()
for p in "${PATHS[@]}"; do
  if git status --porcelain "$p" 2>/dev/null | grep -q .; then
    CHANGED+=("$p")
  fi
done

if [[ ${#CHANGED[@]} -eq 0 ]]; then
  echo "No car-thing changes to commit. Skipping."
  exit 0
fi

MSG="${1:-}"
if [[ -z "$MSG" ]]; then
  VERSION="$(node -p "require('$CAR_THING_DIR/deskthing-app/package.json').version" 2>/dev/null || echo "dev")"
  MSG="car-thing: $VERSION - $(date +%Y-%m-%d)"
fi

echo "Staging and committing..."
git add "${PATHS[@]}"
git commit -m "$MSG"

echo "Pushing to origin..."
git push origin HEAD

# Subtree push to deskthing (keeps public repo in sync)
if git remote get-url deskthing &>/dev/null; then
  echo "Syncing to deskthing (8utl3r/deskthing)..."
  git branch -D deskthing-split 2>/dev/null || true
  git subtree split -P car-thing/deskthing-app -b deskthing-split
  git push deskthing deskthing-split:main
  git branch -D deskthing-split 2>/dev/null || true
fi

echo "Reloading Hammerspoon (bridge picks up changes)..."
"$CAR_THING_DIR/scripts/reload-hammerspoon.sh" 2>/dev/null || true

echo "Building and creating release..."
"$CAR_THING_DIR/scripts/release-to-github.sh" "$REPO"

echo "Done. Release created at https://github.com/$REPO/releases"

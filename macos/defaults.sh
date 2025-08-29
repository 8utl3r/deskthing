#!/usr/bin/env bash
set -euo pipefail

APPLY=0
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    --dry-run) APPLY=0 ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

action() {
  if [[ $APPLY -eq 1 ]]; then
    eval "$1"
  else
    echo "DRY: $1"
  fi
}

# Examples (add as needed)
action "defaults write -g KeyRepeat -int 1"
action "defaults write -g InitialKeyRepeat -int 15"
action "defaults write com.apple.dock autohide -bool true"

echo "Restarting affected services (Dock/Finder) if applying..."
if [[ $APPLY -eq 1 ]]; then
  killall Dock 2>/dev/null || true
  killall Finder 2>/dev/null || true
fi

echo "macOS defaults complete (mode: $([[ $APPLY -eq 1 ]] && echo APPLY || echo DRY-RUN))"

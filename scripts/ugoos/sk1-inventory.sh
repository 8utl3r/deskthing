#!/usr/bin/env bash
# Run SK1 system inventory via ADB. Rich dashboard, output to docs/hardware/ugoos-sk1-inventory.txt
# Prerequisite: adb connect 192.168.0.159:5555

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT="${1:-$DOTFILES_ROOT/docs/hardware/ugoos-sk1-inventory.txt}"

exec python3 "$SCRIPT_DIR/sk1-inventory-rich.py" "$OUTPUT"

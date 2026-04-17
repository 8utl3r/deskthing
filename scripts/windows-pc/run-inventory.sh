#!/usr/bin/env bash
# Run Windows system inventory via SSH. Uses run-inventory-rich.py for Rich UI.
# Usage: ./run-inventory.sh [output_path]
#   ./run-inventory.sh                    # prints to stdout
#   ./run-inventory.sh /path/to/TOC.md    # save to file

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/run-inventory-rich.py" ]]; then
  exec python3 "$SCRIPT_DIR/run-inventory-rich.py" "$@"
else
  echo "Error: run-inventory-rich.py not found" >&2
  exit 1
fi

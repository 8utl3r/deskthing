#!/usr/bin/env bash
# Run a command with no network access (macOS sandbox).
# Usage: run-no-network.sh -- <command> [args...]
# Example: run-no-network.sh -- python examples/test_model_12hz_base.py
set -e
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
PROFILE="${SCRIPT_DIR}/no-network.sb"
if [[ ! -f "$PROFILE" ]]; then
  echo "Sandbox profile not found: $PROFILE" >&2
  exit 1
fi
if [[ "$1" != "--" ]] || [[ $# -lt 2 ]]; then
  echo "Usage: $0 -- <command> [args...]" >&2
  echo "Example: $0 -- python examples/test_model_12hz_base.py" >&2
  exit 1
fi
shift
exec sandbox-exec -f "$PROFILE" -- "$@"

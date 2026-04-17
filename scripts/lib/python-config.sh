#!/bin/bash
# Canonical Python config for dotfiles
# Source this in scripts to get PYTHON3_PATH
# See docs/PYTHON_SETUP_ANALYSIS.md for rationale

CANONICAL_PYTHON="${HOME}/.local/share/mise/installs/python/3.12.11/bin/python3"
if [[ -x "$CANONICAL_PYTHON" ]]; then
  export PYTHON3_PATH="$CANONICAL_PYTHON"
else
  export PYTHON3_PATH="python3"
fi

#!/usr/bin/env bash
# Reload Hammerspoon config so the Car Thing bridge picks up changes.
# Tries: 1) bridge POST /reload, 2) hs CLI, 3) touch file for pathwatcher.
#
# Usage: ./car-thing/scripts/reload-hammerspoon.sh

set -e

# 1. Try bridge first (works after first successful reload)
HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d '{}' http://127.0.0.1:8765/reload 2>/dev/null)
if [[ "$HTTP" == "200" ]]; then
  echo "Hammerspoon reload triggered via bridge."
  exit 0
fi

# 2. Try hs CLI (requires hs.ipc in init.lua)
if command -v hs &>/dev/null && hs -c "hs.reload()" 2>/dev/null; then
  echo "Hammerspoon reload triggered via hs CLI."
  exit 0
fi

# 3. Fallback: touch bridge file (bridge watches itself and reloads)
CONFIG_DIR="${HAMMERSPOON_CONFIG:-$HOME/.hammerspoon}"
for f in "$CONFIG_DIR/modules/car-thing-bridge.lua" "$CONFIG_DIR/init.lua"; do
  if [[ -f "$f" ]]; then
    touch "$f"
    echo "Touched $f to trigger reload."
    exit 0
  fi
done

echo "Could not reload Hammerspoon. Try: Hammerspoon menu → Reload Config" >&2
exit 1

#!/usr/bin/env bash
# Start the DeskThing app dev server. Kills any process already using ports 3000 or 8080.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/../deskthing-app" && pwd)"

# Ports used by @deskthing/cli dev (3000 = dev server, 8080 = WebSocket)
PORTS=(3000 8080)

for port in "${PORTS[@]}"; do
  pid=$(lsof -t -i ":$port" 2>/dev/null || true)
  if [[ -n "$pid" ]]; then
    echo "Killing process $pid on port $port..."
    kill "$pid" 2>/dev/null || true
    sleep 1
    # Force kill if still in use
    pid=$(lsof -t -i ":$port" 2>/dev/null || true)
    if [[ -n "$pid" ]]; then
      kill -9 "$pid" 2>/dev/null || true
      sleep 0.5
    fi
  fi
done

cd "$APP_DIR"
exec npm run dev

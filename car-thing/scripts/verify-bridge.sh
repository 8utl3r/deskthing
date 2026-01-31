#!/usr/bin/env bash
# Verify Car Thing bridge is reachable. Run from repo root or car-thing/.
# Usage: ./car-thing/scripts/verify-bridge.sh

set -euo pipefail

BRIDGE_URL="${CAR_THING_BRIDGE_URL:-http://127.0.0.1:8765}"
OK=0
FAIL=0

check() {
  if [[ "$1" == "ok" ]]; then
    echo "  OK: $2"
    ((OK++)) || true
  else
    echo "  FAIL: $2"
    ((FAIL++)) || true
  fi
}

echo "Car Thing bridge verification"
echo "  URL: $BRIDGE_URL"
echo ""

# 1. Port listening
if lsof -i :8765 &>/dev/null; then
  check ok "Port 8765 is in use (bridge likely running)"
else
  check fail "Port 8765 not in use (reload Hammerspoon?)"
fi

# 2. GET /health
HEALTH_RESP=$(curl -s -w "\n%{http_code}" -m 2 "$BRIDGE_URL/health" 2>/dev/null) || true
HEALTH_CODE=$(echo "$HEALTH_RESP" | tail -1)
HEALTH_BODY=$(echo "$HEALTH_RESP" | sed '$d')
if [[ "$HEALTH_CODE" == "200" && "$HEALTH_BODY" == *"ok"* ]]; then
  check ok "GET /health → 200 $HEALTH_BODY"
else
  check fail "GET /health → code=$HEALTH_CODE body=$HEALTH_BODY (expected 200 and {\"ok\":true})"
fi

# 3. POST /control (volume)
CONTROL_RESP=$(curl -s -w "\n%{http_code}" -m 2 -X POST "$BRIDGE_URL/control" \
  -H "Content-Type: application/json" \
  -d '{"action":"volume","value":50}' 2>/dev/null) || true
CONTROL_CODE=$(echo "$CONTROL_RESP" | tail -1)
CONTROL_BODY=$(echo "$CONTROL_RESP" | sed '$d')
if [[ "$CONTROL_CODE" == "200" && "$CONTROL_BODY" == *"ok"* ]]; then
  check ok "POST /control (volume 50) → 200 $CONTROL_BODY"
else
  check fail "POST /control → code=$CONTROL_CODE body=$CONTROL_BODY"
fi

# 4. Boot log (did bridge init run? cat /tmp/car-thing-bridge.log)
if [[ -f /tmp/car-thing-bridge.log ]]; then
  LAST=$(tail -1 /tmp/car-thing-bridge.log)
  if [[ "$LAST" == *"listening on 8765"* ]]; then
    check ok "Bridge boot log: $LAST"
  elif [[ "$LAST" == *"FAILED"* ]]; then
    check fail "Bridge boot log: $LAST"
  else
    check ok "Bridge boot log (init ran): $LAST"
  fi
else
  check fail "Bridge boot log missing (init never ran? Reload Hammerspoon and check Console for errors)"
fi

# 5. Bridge file exists and is not a self-symlink (if we're in dotfiles; repo root is 2 levels up from car-thing/scripts)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BRIDGE_FILE="$REPO_ROOT/hammerspoon/modules/car-thing-bridge.lua"
if [[ -e "$BRIDGE_FILE" ]]; then
  if [[ -L "$BRIDGE_FILE" ]]; then
    TARGET=$(readlink "$BRIDGE_FILE")
    # Self-referential: target equals this file's path (common when link script links into already-symlinked dir)
    LINK_DIR=$(cd "$(dirname "$BRIDGE_FILE")" && pwd)
    if [[ "$TARGET" == "$BRIDGE_FILE" ]] || [[ "$TARGET" == "$LINK_DIR/car-thing-bridge.lua" ]]; then
      check fail "Bridge file is a self-referential symlink. Run: rm '$BRIDGE_FILE' then restore the real file."
    else
      check ok "Bridge file is symlink → $TARGET"
    fi
  else
    check ok "Bridge file is a regular file"
  fi
fi

echo ""
if [[ $FAIL -gt 0 ]]; then
  echo "Result: $FAIL failure(s). Fix the FAIL lines above, then reload Hammerspoon and re-run."
  exit 1
else
  echo "Result: all checks passed."
  exit 0
fi

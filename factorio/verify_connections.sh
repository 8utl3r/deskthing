#!/usr/bin/env bash
# Connection verification: run in order, stop at first failure.
# Usage: cd factorio && RCON_PASSWORD='your_password' ./verify_connections.sh
# Env: RCON_HOST (default 127.0.0.1), RCON_PORT (27015), RCON_PASSWORD, CONTROLLER_URL (default http://127.0.0.1:8080)

set -e
RCON_HOST="${RCON_HOST:-127.0.0.1}"
RCON_PORT="${RCON_PORT:-27015}"
CONTROLLER_URL="${CONTROLLER_URL:-http://127.0.0.1:8080}"
export RCON_HOST RCON_PORT
[ -n "$RCON_PASSWORD" ] && export RCON_PASSWORD

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

fail() { echo -e "${RED}FAIL: $*${NC}" >&2; exit 1; }
ok()   { echo -e "${GREEN}OK: $*${NC}"; }
warn() { echo -e "${YELLOW}$*${NC}"; }

echo "========================================"
echo "Connection verification (Factorio stack)"
echo "========================================"
echo "RCON: ${RCON_HOST}:${RCON_PORT}"
echo "Controller: ${CONTROLLER_URL}"
echo ""

# ---- Step 1: Factorio RCON reachable ----
echo "Step 1: Factorio RCON reachable"
echo "----------------------------------------"
if command -v nc >/dev/null 2>&1; then
  if nc -zv -w 3 "$RCON_HOST" "$RCON_PORT" 2>/dev/null; then
    ok "RCON port ${RCON_HOST}:${RCON_PORT} is open"
  else
    fail "RCON port ${RCON_HOST}:${RCON_PORT} unreachable. Is Factorio running? Is port 27015 exposed?"
  fi
else
  warn "nc not found, skipping port check"
fi

if [ -n "$RCON_PASSWORD" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  cd "$SCRIPT_DIR"
  if python3 -c "
import os, sys
import factorio_rcon
h, p, pw = os.environ['RCON_HOST'], int(os.environ['RCON_PORT']), os.environ['RCON_PASSWORD']
r = factorio_rcon.RCONClient(h, p, pw)
r.connect()
r.send_command('/sc return 1')
r.close()
" 2>/dev/null; then
    ok "RCON auth and command succeeded"
  else
    fail "RCON auth or command failed. Check RCON_PASSWORD and Factorio RCON settings."
  fi
else
  warn "RCON_PASSWORD not set; skipping RCON auth check. Set it to fully verify Step 1."
fi
echo ""

# ---- Step 2: Controller up and RCON-connected ----
echo "Step 2: Controller up and RCON-connected"
echo "----------------------------------------"
HEALTH="$(curl -s -f "${CONTROLLER_URL}/health" 2>/dev/null)" || true
if [ -z "$HEALTH" ]; then
  fail "Controller not responding at ${CONTROLLER_URL}/health. Is the controller app running? network_mode: host?"
fi
if echo "$HEALTH" | grep -q '"rcon":"connected"'; then
  ok "Controller healthy, RCON connected"
else
  fail "Controller returned health but rcon is not 'connected'. Fix Step 1 (Factorio RCON), then restart the controller."
fi
echo ""

# ---- Step 3: n8n can reach controller ----
echo "Step 3: n8n → controller (execute-action)"
echo "----------------------------------------"
RESP="$(curl -s -X POST "${CONTROLLER_URL}/execute-action" \
  -H 'Content-Type: application/json' \
  -d '{"agent_id":"1","action":"walk_to","params":{"x":0,"y":0}}' 2>/dev/null)" || true
if [ -z "$RESP" ]; then
  fail "No response from /execute-action. Check controller logs and n8n host network."
fi
if echo "$RESP" | grep -q '"success"'; then
  ok "execute-action returned JSON with 'success'"
elif echo "$RESP" | grep -qi "unknown interface\|error\|cannot"; then
  ok "execute-action returned (expected error if no agent_1 yet): $(echo "$RESP" | head -c 80)..."
else
  warn "Unexpected response: $(echo "$RESP" | head -c 120)"
fi
echo ""

echo "========================================"
echo -e "${GREEN}All connection checks passed.${NC}"
echo "If n8n uses host network and calls http://localhost:8080/execute-action, the pipeline is connected."
echo "========================================"

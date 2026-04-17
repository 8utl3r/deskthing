#!/usr/bin/env bash
# Verify Cursor API Bridge v2: list + fallback.
# Run from a host that receives webhook response bodies (NAS or LAN host).
# Usage: ./verify_bridge.sh [bridge_url]

set -e
BRIDGE_URL="${1:-${N8N_BRIDGE_URL:-http://192.168.0.158:30109/webhook/cursor-workflow-api}}"
PASS=0
FAIL=0

run() {
  local op="$1"
  local body="$2"
  curl -s -X POST "$BRIDGE_URL" -H "Content-Type: application/json" -d "$body"
}

check_list() {
  echo "--- list ---"
  local resp
  resp=$(run '{"operation":"list"}')
  local len=${#resp}
  if [[ "$len" -eq 0 ]]; then
    echo "FAIL: empty response (run this script from NAS or a host that gets webhook bodies)"
    ((FAIL++)) || true
    return
  fi
  if command -v jq >/dev/null 2>&1; then
    if jq -e '.success == true and .data != null' <<<"$resp" >/dev/null 2>&1; then
      echo "PASS: list returned success and data"
      ((PASS++)) || true
    else
      echo "FAIL: list response missing success/data or success=false"
      echo "$resp" | jq -c . 2>/dev/null || echo "$resp"
      ((FAIL++)) || true
    fi
  else
    if echo "$resp" | grep -q '"success"\s*:\s*true' && echo "$resp" | grep -q '"data"'; then
      echo "PASS: list returned success and data"
      ((PASS++)) || true
    else
      echo "FAIL: list response unexpected"
      echo "$resp"
      ((FAIL++)) || true
    fi
  fi
}

check_fallback() {
  echo "--- fallback (invalid operation) ---"
  local resp
  resp=$(run '{"operation":"__invalid__"}')
  local len=${#resp}
  if [[ "$len" -eq 0 ]]; then
    echo "FAIL: empty response (run this script from NAS or a host that gets webhook bodies)"
    ((FAIL++)) || true
    return
  fi
  if command -v jq >/dev/null 2>&1; then
    if jq -e '.success == false and (.error | test("Invalid operation"))' <<<"$resp" >/dev/null 2>&1; then
      echo "PASS: fallback returned success=false and 'Invalid operation'"
      ((PASS++)) || true
    else
      echo "FAIL: fallback response unexpected"
      echo "$resp" | jq -c . 2>/dev/null || echo "$resp"
      ((FAIL++)) || true
    fi
  else
    if echo "$resp" | grep -q '"success"\s*:\s*false' && echo "$resp" | grep -qi 'invalid operation'; then
      echo "PASS: fallback returned success=false and 'Invalid operation'"
      ((PASS++)) || true
    else
      echo "FAIL: fallback response unexpected"
      echo "$resp"
      ((FAIL++)) || true
    fi
  fi
}

echo "Bridge URL: $BRIDGE_URL"
check_list
check_fallback
echo "---"
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]

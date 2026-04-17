#!/usr/bin/env bash
# Verify the full reverse proxy chain for xcvr.link services
# Run from Mac on LAN. Uses Rich if available.

set -e

check() {
  local label="$1"
  local cmd="$2"
  local expect="$3"
  local out
  out=$(eval "$cmd" 2>&1)
  if [[ "$out" == *"$expect"* ]]; then
    echo "✅ $label"
  else
    echo "❌ $label (got: ${out:0:80}...)"
  fi
}

echo "=== Reverse Proxy Chain Verification ==="
echo ""

echo "1. DNS (jellyfin.xcvr.link → 192.168.0.158)"
r=$(dig +short jellyfin.xcvr.link 2>/dev/null)
if [[ "$r" == "192.168.0.158" ]]; then
  echo "   ✅ $r"
else
  echo "   ❌ ${r:-no result} (expected 192.168.0.158)"
fi

echo ""
echo "2. NPM port 80 (receiving traffic)"
h=$(curl -sI -m 5 http://192.168.0.158:80/ 2>&1 | head -1)
if [[ "$h" == *"200"* ]] || [[ "$h" == *"302"* ]] || [[ "$h" == *"301"* ]]; then
  echo "   ✅ $h"
else
  echo "   ❌ $h"
fi

echo ""
echo "3. Jellyfin via NPM (Host: jellyfin.xcvr.link)"
h=$(curl -sI -m 5 -H "Host: jellyfin.xcvr.link" http://192.168.0.158/ 2>&1)
if [[ "$h" == *"302"* ]] && [[ "$h" == *"web/"* ]]; then
  echo "   ✅ NPM routes to Jellyfin (302 → web/)"
elif [[ "$h" == *"200"* ]]; then
  echo "   ✅ NPM responds"
else
  echo "   ❌ $h"
fi

echo ""
echo "4. Full URL (http://jellyfin.xcvr.link)"
h=$(curl -sI -m 5 -w "Exit:%{exitcode}" http://jellyfin.xcvr.link/ 2>&1)
if [[ "$h" == *"302"* ]] && [[ "$h" == *"web/"* ]]; then
  echo "   ✅ jellyfin.xcvr.link works"
elif [[ "$h" == *"Exit:6"* ]] || [[ "$h" == *"Exit:7"* ]]; then
  echo "   ❌ Connection failed (DNS or network). Try: curl -v http://jellyfin.xcvr.link"
else
  echo "   ❓ $h"
fi

echo ""
echo "5. Jellyfin direct (Pi)"
h=$(curl -sI -m 5 http://192.168.0.136:8096/ 2>&1 | head -1)
if [[ "$h" == *"302"* ]]; then
  echo "   ✅ Jellyfin on Pi responds"
else
  echo "   ❌ $h"
fi

echo ""
echo "=== Done ==="

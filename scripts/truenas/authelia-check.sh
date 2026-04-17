#!/usr/bin/env bash
# Check that Authelia is responding (e.g. after deploy/restart).
# Run from Mac or any host that can reach TRUENAS_HOST.
#
# Usage: ./scripts/truenas/authelia-check.sh
# Rich dashboard: python3 scripts/truenas/authelia-dashboard.py [--plain]

set -e

TRUENAS_HOST="${TRUENAS_HOST:-192.168.0.158}"
AUTHELIA_URL="${AUTHELIA_URL:-http://${TRUENAS_HOST}:30133}"

echo "Checking $AUTHELIA_URL ..."
if code=$(curl -sS -o /dev/null -w "%{http_code}" --connect-timeout 5 "$AUTHELIA_URL/"); then
  if [[ "$code" =~ ^(200|302)$ ]]; then
    echo "OK HTTP $code"
    exit 0
  else
    echo "Unexpected HTTP $code (expected 200 or 302)" >&2
    exit 1
  fi
else
  echo "Connection failed (Authelia may be down or unreachable)" >&2
  exit 1
fi

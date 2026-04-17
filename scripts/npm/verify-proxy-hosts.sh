#!/usr/bin/env bash
# Verify every NPM+ proxy host: list from API, then request each through the proxy.
# Usage: ./verify-proxy-hosts.sh [NPM_URL]
# Default NPM_URL: https://192.168.0.158:30020 (or 30360 if 30020 not reachable)

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NPM_URL_ENV="${NPM_URL:-}"
source "$SCRIPT_DIR/.env" 2>/dev/null || true
[[ -n "$NPM_URL_ENV" ]] && NPM_URL="$NPM_URL_ENV"
: "${NPM_URL:=https://192.168.0.158:30020}"
# NPM+ requires HTTPS (cookie auth); ensure we use it
[[ "$NPM_URL" == http://* ]] && NPM_URL="https://${NPM_URL#http://}"

# If API unreachable, try fallback port
if ! curl -sk --connect-timeout 2 -o /dev/null "$NPM_URL/api/" 2>/dev/null; then
  NPM_URL="https://192.168.0.158:30360"
fi

PROXY_HTTP="http://192.168.0.158:80"
echo "=== NPM+ proxy host verification ==="
echo "NPM API: $NPM_URL"
echo "Proxy:   $PROXY_HTTP"
echo ""

# List from API (requires .env with NPM_EMAIL/NPM_PASSWORD or NPM_TOKEN)
echo "--- Hosts from API ---"
if ! NPM_URL="$NPM_URL" "$SCRIPT_DIR/npm-api.sh" list 2>/dev/null; then
  echo "(Could not list from API; check scripts/npm/.env)"
  exit 1
fi
echo ""

# Test each host through proxy
echo "--- Per-host check (Host header → $PROXY_HTTP) ---"
for host in nas.xcvr.link headscale.xcvr.link sso.xcvr.link rules.xcvr.link immich.xcvr.link n8n.xcvr.link syncthing.xcvr.link jellyfin.xcvr.link music.xcvr.link; do
  code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 -H "Host: $host" "$PROXY_HTTP/" 2>/dev/null)
  if [[ "$code" =~ ^(200|301|302|307|308)$ ]]; then
    echo "  OK   $host → $code"
  else
    echo "  FAIL $host → $code"
  fi
done
echo ""
echo "Done. 2xx/3xx = proxy and backend OK. 502 = backend unreachable (e.g. hostname 'authelia' not resolved in container)."

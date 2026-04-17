#!/usr/bin/env bash
# Remove old NPM (nginx-proxy-manager) and set NPM+ to use ports 30020, 80, 443.
# Run from your Mac. Requires factorio/.env.nas with NAS_SUDO_PASSWORD.
#
# Steps:
#   1. Uninstall old NPM app (if present).
#   2. Update NPM+ app network: Web UI 30020, HTTP 80, HTTPS 443.
#   3. Restart NPM+ so new ports take effect.
#
# See: docs/truenas/npm-to-npmplus-migration.md

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/factorio/.env.nas" 2>/dev/null || { echo "Missing factorio/.env.nas"; exit 1; }
TRUENAS_HOST="${TRUENAS_HOST:-192.168.0.158}"
TRUENAS_USER="${TRUENAS_USER:-truenas_admin}"

# App names (release names in TrueNAS)
OLD_NPM_RELEASES="nginx-proxy-manager nginx_proxy_manager"
NPMPLUS_RELEASE="npmplus"

run_nas() {
  local cmd="$1"
  printf '%s\n' "$cmd" | ssh "$TRUENAS_USER@$TRUENAS_HOST" "echo '${NAS_SUDO_PASSWORD}' | sudo -S bash -s"
}

echo "=== Remove NPM and set NPM+ ports ==="
echo "Host: $TRUENAS_USER@$TRUENAS_HOST"
echo ""

# 1. Uninstall old NPM (try common release names)
echo "1. Uninstalling old NPM app (if installed)..."
for name in $OLD_NPM_RELEASES; do
  out=$(run_nas "midclt call app.get_instance $name 2>/dev/null" 2>/dev/null) || true
  if [[ -n "$out" && "$out" != "null" && "$out" != "[]" ]]; then
    echo "   Found: $name — removing..."
    run_nas "midclt call app.delete $name" 2>/dev/null && echo "   Removed $name." || echo "   (delete failed; uninstall via Apps → Installed → $name → Uninstall)"
  fi
done
echo "   Done."
echo ""

# 2. Set NPM+ ports: Web UI 30020, HTTP 80, HTTPS 443
echo "2. Setting NPM+ ports (Web UI 30020, HTTP 80, HTTPS 443)..."
run_nas 'V="{\"values\":{\"network\":{\"web_port\":{\"bind_mode\":\"published\",\"port_number\":30020},\"http_port\":{\"bind_mode\":\"published\",\"port_number\":80},\"https_port\":{\"bind_mode\":\"published\",\"port_number\":443}}}}"; midclt call -j app.update npmplus "$V"' 2>/dev/null && echo "   Update submitted." || echo "   midclt app.update failed or not supported. Use UI: Apps → Installed → npmplus → Edit → Network: set WebUI 30020, HTTP 80, HTTPS 443 → Save."
echo ""

# 3. Restart NPM+ so new ports take effect
echo "3. Restarting NPM+..."
if run_nas "midclt call app.restart $NPMPLUS_RELEASE" 2>/dev/null; then
  echo "   Restart triggered. Wait ~1 minute, then use: https://$TRUENAS_HOST:30020"
else
  echo "   Restart via API failed. Restart manually: Apps → Installed → npmplus → Restart."
fi
echo ""
echo "Done. NPM+ admin: https://$TRUENAS_HOST:30020  (proxy on 80/443)."

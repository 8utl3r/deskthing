#!/usr/bin/env bash
# Fix Syncthing upgrade blocked by "path contains existing data and force was not specified".
# Disables host path safety checks, runs the upgrade, then re-enables checks.
#
# Run from your Mac (requires factorio/.env.nas with NAS_SUDO_PASSWORD):
#   ./scripts/truenas/syncthing-upgrade-fix.sh
#
# Or run on TrueNAS via SSH (no password needed for midclt when already root):
#   ssh truenas_admin@192.168.0.158
#   sudo -i   # or use a script that runs midclt as root
#   midclt call app.kubernetes_config   # discover; then see IN-NAS section below
#
# See: docs/truenas/truenas-syncthing-setup.md

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/factorio/.env.nas" 2>/dev/null || { echo "Missing factorio/.env.nas (need NAS_SUDO_PASSWORD)."; exit 1; }
TRUENAS_HOST="${TRUENAS_HOST:-192.168.0.158}"
TRUENAS_USER="${TRUENAS_USER:-truenas_admin}"
APP_NAME="syncthing"

# Run a single command on the NAS with sudo (password from env).
run_nas() {
  local cmd="$1"
  printf '%s\n' "$cmd" | ssh "$TRUENAS_USER@$TRUENAS_HOST" "echo '${NAS_SUDO_PASSWORD}' | sudo -S bash -s"
}

echo "=== Syncthing upgrade fix (disable host path checks → upgrade → re-enable) ==="
echo "Host: $TRUENAS_USER@$TRUENAS_HOST"
echo ""

# 1) Get current Kubernetes/Apps config to find the safety-check setting name
echo "1. Checking app/kubernetes config for host path safety setting..."
KUBE_JSON=$(run_nas 'midclt call app.kubernetes_config 2>/dev/null' 2>/dev/null) || true
if [[ -n "$KUBE_JSON" ]]; then
  echo "$KUBE_JSON" | head -c 500
  echo ""
  # Common key names: host_path_validation, hostpath_validation, validate_host_path
  if echo "$KUBE_JSON" | grep -qE 'host_path|hostpath|validation'; then
    echo "   (Found host-path-related keys above)"
  fi
else
  echo "   Could not get app.kubernetes_config (method may differ on your version)."
fi
echo ""

# 2) Try to disable the check via app.kubernetes_update (key name varies by version)
echo "2. Disabling host path safety checks..."
DISABLED=false
for key in host_path_validation validate_host_path hostpath_validation; do
  OUT=$(run_nas "midclt call -j app.kubernetes_update '{\"$key\": false}' 2>&1") || true
  if [[ -z "$OUT" || "$OUT" != *"does not exist"* ]]; then
    DISABLED=true
    echo "   Set $key = false."
    break
  fi
done

if [[ "$DISABLED" != "true" ]]; then
  echo "   Could not disable via app.kubernetes_update."
  echo ""
  echo "Do this manually in the TrueNAS UI:"
  echo "  1. Apps → Settings (gear) → Advanced Settings"
  echo "  2. Uncheck 'Enable Host Path Safety Checks'"
  echo "  3. Save"
  echo "  4. Apps → Installed → Syncthing → Upgrade"
  echo "  5. Re-enable 'Enable Host Path Safety Checks'"
  exit 1
fi
echo ""

# 3) Trigger upgrade
echo "3. Triggering Syncthing upgrade..."
OUT=$(run_nas "midclt call -j app.upgrade '$APP_NAME' '{}' 2>&1") || true
if [[ "$OUT" != *"error"* && "$OUT" != *"Error"* && -n "$OUT" ]]; then
  echo "   Upgrade job started. Check Apps → Installed for status."
else
  echo "   Run upgrade in UI: Apps → Installed → Syncthing → Upgrade"
fi
echo ""

# 4) Wait for you to run the upgrade in the UI, then re-enable the check
echo "4. Run the upgrade in the UI: Apps → Installed → Syncthing → Upgrade"
echo "   When done, press Enter here to re-enable host path safety checks..."
read -r
echo "   Re-enabling host path safety checks..."
for key in host_path_validation validate_host_path hostpath_validation; do
  run_nas "midclt call -j app.kubernetes_update '{\"$key\": true}' 2>/dev/null" && break
done
echo "Done."

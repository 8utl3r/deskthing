#!/usr/bin/env bash
# Migrate existing NPM (jc21) config and certs into the already-running NPMplus
# TrueNAS app. Finds NPMplus /data path from the running container, stops old NPM,
# copies data and certs, then restarts NPMplus.
#
# After this you log in with your *previous NPM* admin email and password (the
# account in the old NPM DB). If you had already set that same email/password in
# the NPMplus setup form, the copied DB will have that user.
#
# Requires: factorio/.env.nas with NAS_SUDO_PASSWORD
# See: docs/truenas/npm-to-npmplus-migration.md

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/factorio/.env.nas" 2>/dev/null || { echo "Missing factorio/.env.nas"; exit 1; }
TRUENAS_HOST="${TRUENAS_HOST:-192.168.0.158}"
TRUENAS_USER="${TRUENAS_USER:-truenas_admin}"
NPM_DATA="/mnt/.ix-apps/app_mounts/nginx-proxy-manager/data"
NPM_CERTS="/mnt/.ix-apps/app_mounts/nginx-proxy-manager/certs"

run_nas() {
  local cmd="$1"
  printf '%s\n' "$cmd" | ssh "$TRUENAS_USER@$TRUENAS_HOST" "echo '${NAS_SUDO_PASSWORD}' | sudo -S bash -s"
}

if [[ "$1" == --diagnose ]]; then
  echo "=== NPMplus migration diagnostic (uses factorio/.env.nas for sudo) ==="
  echo "Host: $TRUENAS_USER@$TRUENAS_HOST"
  echo ""
  echo "--- Who and PATH ---"
  run_nas "id; echo PATH=\$PATH; which docker 2>/dev/null || echo 'docker not in PATH'"
  echo ""
  echo "--- All Docker containers ---"
  run_nas "docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' 2>&1"
  echo ""
  echo "--- TrueNAS apps (midclt) ---"
  run_nas "midclt call app.query 2>&1 | head -100"
  echo ""
  echo "--- NPMplus app instance (if exists) ---"
  run_nas "midclt call app.get_instance npmplus 2>&1"
  echo ""
  echo "--- /mnt contents ---"
  run_nas "ls -la /mnt 2>&1"
  echo ""
  echo "--- /mnt/.ix-apps if present ---"
  run_nas "ls -la /mnt/.ix-apps 2>&1; ls -la /mnt/.ix-apps/app_mounts 2>&1"
  echo ""
  echo "--- Any app_mounts under /mnt ---"
  run_nas "find /mnt -maxdepth 5 -type d -name app_mounts 2>&1"
  exit 0
fi

echo "=== Migrate NPM → NPMplus (TrueNAS app) ==="
echo "Host: $TRUENAS_USER@$TRUENAS_HOST"
echo ""

# 1. Find NPMplus data path (TrueNAS 24.10+ uses Docker; container names vary)
echo "1. Finding NPMplus app data path..."
CONTAINER=$(run_nas 'docker ps --format "{{.Names}}" 2>/dev/null | grep -iE "npmplus|npm-plus|nginx-proxy-manager-plus|proxy-manager" | head -1' || true)
if [[ -n "$CONTAINER" ]]; then
  TARGET_DATA=$(run_nas "docker inspect --format '{{range .Mounts}}{{if eq .Destination \"/data\"}}{{.Source}}{{end}}{{end}}' $CONTAINER" 2>/dev/null || true)
  echo "   Container: $CONTAINER"
fi
if [[ -z "$TARGET_DATA" ]]; then
  # Fallback: try ix-apps mount path (Docker or k3s)
  for try in "/mnt/.ix-apps/app_mounts/npmplus/data" "/mnt/.ix-apps/app_mounts/nginx-proxy-manager-plus/data"; do
    if run_nas "test -d '$try' && echo ok" 2>/dev/null | grep -q ok; then
      TARGET_DATA="$try"
      echo "   Using path: $TARGET_DATA"
      break
    fi
  done
fi
if [[ -z "$TARGET_DATA" ]]; then
  echo "   No NPMplus container or data path found. Run with --diagnose to see containers and paths (uses same sudo password):"
  echo "   $0 --diagnose"
  exit 1
fi
echo "   Data path: $TARGET_DATA"
echo ""

# 2. Stop old NPM
echo "2. Stopping old NPM container..."
run_nas 'docker stop ix-nginx-proxy-manager-npm-1 2>/dev/null || true'
run_nas 'docker rm ix-nginx-proxy-manager-npm-1 2>/dev/null || true'
echo "   Done."
echo ""

# 3. Backup NPMplus DB (in case we need to roll back)
echo "3. Backing up NPMplus database..."
run_nas "cp -a '$TARGET_DATA/npmplus/database.sqlite' '$TARGET_DATA/npmplus/database.sqlite.bak' 2>/dev/null || true"
echo "   Done."
echo ""

# 4. Copy NPM database into NPMplus (proxy hosts, certs in DB, etc.)
#    NPM uses data/database.sqlite; NPMplus uses data/npmplus/database.sqlite
echo "4. Copying NPM data into NPMplus..."
run_nas "mkdir -p '$TARGET_DATA/npmplus' && cp -a '$NPM_DATA/database.sqlite' '$TARGET_DATA/npmplus/database.sqlite'"
echo "   Done."
echo ""

# 5. Copy certificate files
echo "5. Copying certificate files..."
run_nas "mkdir -p '$TARGET_DATA/tls/certbot' && rsync -a '$NPM_CERTS/' '$TARGET_DATA/tls/certbot/'"
echo "   Done."
echo ""

# 5b. Ensure app can read (PUID/PGID 568)
run_nas "chown -R 568:568 '$TARGET_DATA/npmplus' '$TARGET_DATA/tls' 2>/dev/null || true"
echo ""

# 6. Restart NPMplus app so it picks up the migrated data
echo "6. Restarting NPMplus app..."
if run_nas "midclt call app.restart npmplus 2>/dev/null"; then
  echo "   Restart triggered. Wait a minute, then open the NPMplus UI."
else
  echo "   Could not restart via API. Restart the app manually: Apps → Installed → npmplus → Restart"
fi
echo ""
echo "Done. Log in with your **previous NPM** admin email and password."
echo "Admin UI: http://$TRUENAS_HOST:30360 (or 30020 after you change ports and remove old NPM)."

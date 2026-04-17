#!/usr/bin/env bash
# Fetch Authelia notifier output (filesystem) from TrueNAS.
# Writes output to scripts/truenas/output/ so the agent can read results.
#
# Usage:
#   ./scripts/truenas/authelia-notifications.sh

set -e

TRUENAS_HOST="${TRUENAS_HOST:-192.168.0.158}"
TRUENAS_USER="${TRUENAS_USER:-truenas_admin}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREDS_SH="${CREDS_SH:-$HOME/dotfiles/scripts/credentials/creds.sh}"
CONF_DIR="${AUTHELIA_CONF_DIR:-/mnt/.ix-apps/app_mounts/authelia/config}"

LOG_DIR="$SCRIPT_DIR/output"
LOG_FILE="$LOG_DIR/authelia-notifications-$(date +%Y%m%d-%H%M%S).txt"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

if [[ ! -f "${CREDS_SH:-}" ]]; then
  echo "Error: $CREDS_SH not found. Need truenas-sudo for SSH sudo." >&2
  exit 1
fi
# shellcheck source=../credentials/creds.sh
source "$CREDS_SH" 2>/dev/null || true
PASS=$(creds_get truenas-sudo 2>/dev/null)
if [[ -z "$PASS" ]]; then
  echo "Error: no truenas-sudo credential. See scripts/credentials/README.md" >&2
  exit 1
fi

echo "Fetching notification.txt from $TRUENAS_HOST..."
ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
  "echo -n '$PASS' | sudo -S CONF_DIR='$CONF_DIR' python3 - <<'PY'
from pathlib import Path
import os
conf_dir = os.environ.get('CONF_DIR', '/mnt/.ix-apps/app_mounts/authelia/config')
path = Path(conf_dir) / 'notification.txt'
if not path.exists():
    raise SystemExit(f'Missing {path}')
print(path.read_text(errors='replace'))
PY" 2>&1 | grep -v "bleep blorp" | grep -v "\[sudo\] password for"
[[ ${PIPESTATUS[0]} -eq 0 ]] || exit 1

echo "Log: $LOG_FILE"

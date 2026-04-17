#!/usr/bin/env bash
# Restart the Authelia app container on TrueNAS so it picks up config/permission changes.
# Run from Mac. Requires: truenas-sudo in keychain, SSH to truenas_admin@TRUENAS_HOST.
#
# Usage: ./scripts/truenas/authelia-restart.sh
# Rich dashboard: python3 scripts/truenas/authelia-dashboard.py [--plain]

set -e

TRUENAS_HOST="${TRUENAS_HOST:-192.168.0.158}"
TRUENAS_USER="${TRUENAS_USER:-truenas_admin}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREDS_SH="${CREDS_SH:-$HOME/dotfiles/scripts/credentials/creds.sh}"

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

_filter_ssh() { grep -v "bleep blorp" | grep -v "\[sudo\] password for"; }

CONTAINER="ix-authelia-authelia-1"
echo "Restarting $CONTAINER on $TRUENAS_HOST..."
ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
  "echo -n '$PASS' | sudo -S docker restart $CONTAINER 2>/dev/null" 2>&1 | _filter_ssh || true
echo "Done. Check with: ./scripts/truenas/authelia-check.sh"

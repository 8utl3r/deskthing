#!/usr/bin/env bash
# One-off fix: set ownership and world-read on Authelia config/data so the container can read users_database.yml.
# Use after copying files manually or if deploy script's permissions weren't applied. Then run authelia-restart.sh.
# Run from Mac. Requires: truenas-sudo in keychain, SSH to truenas_admin@TRUENAS_HOST.
#
# Usage: ./scripts/truenas/authelia-fix-permissions.sh
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

CONF_DIR="${AUTHELIA_CONF_DIR:-/mnt/.ix-apps/app_mounts/authelia/config}"
echo "Fixing permissions on $CONF_DIR/data on $TRUENAS_HOST..."
ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
  "echo -n '$PASS' | sudo -S sh -c '
    [ -d \"$CONF_DIR/data\" ] || { echo \"Error: $CONF_DIR/data not found\"; exit 1; }
    chown -R 568:568 \"$CONF_DIR/data\"
    chmod 755 \"$CONF_DIR/data\"
    chmod 644 \"$CONF_DIR/data/users_database.yml\" 2>/dev/null || true
    chmod -R o+rX \"$CONF_DIR/data\"
    echo Done.
  '" 2>&1 | _filter_ssh
[[ ${PIPESTATUS[0]} -eq 0 ]] || exit 1
echo "Next: ./scripts/truenas/authelia-restart.sh"

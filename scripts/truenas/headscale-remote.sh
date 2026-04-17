#!/usr/bin/env bash
# Run Headscale CLI on TrueNAS via SSH (no gRPC needed).
# Uses truenas-sudo from keychain (creds_get truenas-sudo).
#
# Usage:
#   headscale-remote.sh nodes list
#   headscale-remote.sh nodes list-routes
#   headscale-remote.sh nodes approve-routes --identifier 2 --routes 192.168.0.0/24
#   headscale-remote.sh users list
#
# Requires: SSH to truenas_admin@TRUENAS_HOST, and keychain entry "truenas-sudo".

set -e

TRUENAS_HOST="${TRUENAS_HOST:-192.168.0.158}"
TRUENAS_USER="${TRUENAS_USER:-truenas_admin}"
HEADSCALE_CONTAINER="${HEADSCALE_CONTAINER:-ix-headscale-headscale-1}"
CREDS_SH="${CREDS_SH:-$HOME/dotfiles/scripts/credentials/creds.sh}"

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <headscale args...>" >&2
  echo "Example: $0 nodes list" >&2
  exit 1
fi

if [[ ! -f "$CREDS_SH" ]]; then
  echo "Creds script not found: $CREDS_SH" >&2
  exit 1
fi

source "$CREDS_SH" 2>/dev/null || true
PASS=$(creds_get truenas-sudo 2>/dev/null)
if [[ -z "$PASS" ]]; then
  echo "No truenas-sudo in keychain. See scripts/credentials/README.md" >&2
  exit 1
fi

ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
  "echo -n '$PASS' | sudo -S docker exec $HEADSCALE_CONTAINER headscale $*" 2>&1 | \
  grep -v "bleep blorp" | grep -v "password for truenas_admin"

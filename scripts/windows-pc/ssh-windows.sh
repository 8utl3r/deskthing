#!/usr/bin/env bash
# SSH to Windows PC (192.168.0.47) via password auth
# Requires: scripts/windows-pc/.env or scripts/ugoos/.env with WINDOWS_SSH_PASSWORD
#
# Usage: ./ssh-windows.sh [command]
#   ./ssh-windows.sh              # interactive shell
#   ./ssh-windows.sh "hostname"   # run command remotely

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
if [[ ! -f "$ENV_FILE" ]] && [[ -f "$SCRIPT_DIR/../ugoos/.env" ]]; then
  ENV_FILE="$SCRIPT_DIR/../ugoos/.env"
fi

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
fi

: "${WINDOWS_SSH_PASSWORD:?Set WINDOWS_SSH_PASSWORD in scripts/windows-pc/.env or scripts/ugoos/.env}"
: "${WINDOWS_SSH_USER:=pete}"
: "${WINDOWS_SSH_HOST:=192.168.0.47}"

export SSHPASS="$WINDOWS_SSH_PASSWORD"
exec sshpass -e ssh -o StrictHostKeyChecking=accept-new "$WINDOWS_SSH_USER@$WINDOWS_SSH_HOST" "$@"

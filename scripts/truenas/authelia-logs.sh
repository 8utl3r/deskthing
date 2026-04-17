#!/usr/bin/env bash
# Fetch Authelia app container logs from TrueNAS via SSH.
# Uses same creds as authelia-deploy-config.sh (truenas-sudo). Run from Mac.
#
# Usage: ./scripts/truenas/authelia-logs.sh [--tail N]
#   --tail N   show last N lines per container (default 80)

set -e

TRUENAS_HOST="${TRUENAS_HOST:-192.168.0.158}"
TRUENAS_USER="${TRUENAS_USER:-truenas_admin}"
CREDS_SH="${CREDS_SH:-$HOME/dotfiles/scripts/credentials/creds.sh}"
TAIL="${AUTHELIA_LOGS_TAIL:-80}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tail) TAIL="$2"; shift 2 ;;
    *) echo "Usage: $0 [--tail N]" >&2; exit 1 ;;
  esac
done

if [[ ! -f "${CREDS_SH:-}" ]]; then
  echo "Error: $CREDS_SH not found. Need truenas-sudo for SSH sudo." >&2
  exit 1
fi
source "$CREDS_SH" 2>/dev/null || true
PASS=$(creds_get truenas-sudo 2>/dev/null)
if [[ -z "$PASS" ]]; then
  echo "Error: no truenas-sudo credential. See scripts/credentials/README.md" >&2
  exit 1
fi

_filter_ssh() { grep -v "bleep blorp" | grep -v "\[sudo\] password for"; }

echo "=== Authelia app workload containers on $TRUENAS_HOST ==="
# All containers in the ix-authelia app: authelia, postgres, redis, permissions, postgres_upgrade
CONTAINERS=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
  "echo -n '$PASS' | sudo -S docker ps -a --format '{{.Names}}\t{{.Status}}' 2>/dev/null" 2>&1 | _filter_ssh | grep 'ix-authelia-' | sort)

if [[ -z "$CONTAINERS" ]]; then
  echo "No ix-authelia-* containers found. Listing all containers:"
  ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
    "echo -n '$PASS' | sudo -S docker ps -a --format '{{.Names}}\t{{.Status}}' 2>/dev/null" 2>&1 | _filter_ssh || true
  exit 0
fi

echo "Containers: $(echo "$CONTAINERS" | wc -l | tr -d ' ')"
echo ""

# Single SSH: loop on server to get logs for all containers (avoids multiple sudo prompts)
readarray -t NAMES < <(echo "$CONTAINERS" | awk '{print $1}')
# shellcheck disable=SC2029
ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
  "echo -n '$PASS' | sudo -S sh -c '
    for name in \"\$@\"; do
      [ -z \"\$name\" ] && continue
      status=\$(sudo docker ps -a --format \"{{.Status}}\" --filter \"name=^\${name}\$\" 2>/dev/null | head -1)
      echo \"\"
      echo \"--- \$name (\${status:-?}) ---\"
      sudo docker logs \"\$name\" --tail $TAIL 2>&1 || true
    done
  ' _ ${NAMES[*]}" 2>&1 | _filter_ssh

echo ""
echo "Done. Increase lines with: $0 --tail 200"

#!/usr/bin/env bash
# Set email for a user in Authelia users_database.yml on TrueNAS.
# Writes output to scripts/truenas/output/ so the agent can read results.
#
# Usage:
#   ./scripts/truenas/authelia-set-email.sh pete pete@example.com
#   ./scripts/truenas/authelia-set-email.sh            # prompts

set -e

TRUENAS_HOST="${TRUENAS_HOST:-192.168.0.158}"
TRUENAS_USER="${TRUENAS_USER:-truenas_admin}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREDS_SH="${CREDS_SH:-$HOME/dotfiles/scripts/credentials/creds.sh}"
CONF_DIR="${AUTHELIA_CONF_DIR:-/mnt/.ix-apps/app_mounts/authelia/config}"

LOG_DIR="$SCRIPT_DIR/output"
LOG_FILE="$LOG_DIR/authelia-set-email-$(date +%Y%m%d-%H%M%S).txt"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

USERNAME="${1:-}"
EMAIL="${2:-}"

if [[ -z "$USERNAME" ]]; then
  read -rp "Authelia username: " USERNAME
fi
if [[ -z "$EMAIL" ]]; then
  read -rp "Email for $USERNAME: " EMAIL
fi
if [[ -z "$USERNAME" || -z "$EMAIL" ]]; then
  echo "Error: username and email are required." >&2
  exit 1
fi

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

echo "Setting email for $USERNAME on $TRUENAS_HOST..."
ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
  "echo -n '$PASS' | sudo -S USERNAME='$USERNAME' EMAIL='$EMAIL' CONF_DIR='$CONF_DIR' python3 - <<'PY'
import os
import re
import shutil
from datetime import datetime
from pathlib import Path

username = os.environ.get('USERNAME', '').strip()
email = os.environ.get('EMAIL', '').strip().replace('\"', '\\\\\"')
conf_dir = os.environ.get('CONF_DIR', '/mnt/.ix-apps/app_mounts/authelia/config')
path = Path(conf_dir) / 'data' / 'users_database.yml'

if not username or not email:
    raise SystemExit('USERNAME and EMAIL are required')
if not path.exists():
    raise SystemExit(f'Missing users_database.yml at {path}')

text = path.read_text(errors='replace')
lines = text.splitlines()

user_line = f\"  {username}:\"
user_idx = None
for i, line in enumerate(lines):
    if line.strip() == user_line.strip():
        user_idx = i
        break
if user_idx is None:
    raise SystemExit(f'User {username} not found in {path}')

end_idx = len(lines)
for j in range(user_idx + 1, len(lines)):
    if re.match(r'^  \\S', lines[j]):
        end_idx = j
        break

email_line = f\"    email: \\\"{email}\\\"\"
found = False
for k in range(user_idx + 1, end_idx):
    if lines[k].startswith('    email:'):
        lines[k] = email_line
        found = True
        break

if not found:
    insert_at = user_idx + 1
    for k in range(user_idx + 1, end_idx):
        if lines[k].startswith('    displayname:'):
            insert_at = k + 1
            break
    lines.insert(insert_at, email_line)

backup = path.with_suffix(f\".yml.bak.{datetime.now().strftime('%Y%m%d-%H%M%S')}\")
shutil.copy(path, backup)
path.write_text(\"\\n\".join(lines) + \"\\n\")
print(f\"Updated {path}\")
print(f\"Backup saved to {backup}\")
PY" 2>&1 | grep -v "bleep blorp" | grep -v "\[sudo\] password for"
[[ ${PIPESTATUS[0]} -eq 0 ]] || exit 1

echo "Done. Restart Authelia to pick up the change:"
echo "  ./scripts/truenas/authelia-restart.sh"
echo "Log: $LOG_FILE"

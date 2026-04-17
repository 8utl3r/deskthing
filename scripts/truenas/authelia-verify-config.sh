#!/usr/bin/env bash
# Find and show Authelia configuration.yml session/authz on TrueNAS (for sso.xcvr.link).
# Use to verify session.cookies and server.endpoints.authz match the checklist.
#
# Usage: ./scripts/truenas/authelia-verify-config.sh
#
# Requires: SSH to truenas_admin@TRUENAS_HOST, keychain "truenas-sudo". See scripts/credentials/README.md.

set -e

TRUENAS_HOST="${TRUENAS_HOST:-192.168.0.158}"
TRUENAS_USER="${TRUENAS_USER:-truenas_admin}"
CREDS_SH="${CREDS_SH:-$HOME/dotfiles/scripts/credentials/creds.sh}"

if [[ ! -f "${CREDS_SH:-}" ]]; then
  echo "Creds script not found: $CREDS_SH" >&2
  echo "See scripts/credentials/README.md (truenas-sudo keychain entry)." >&2
  exit 1
fi

source "$CREDS_SH" 2>/dev/null || true
PASS=$(creds_get truenas-sudo 2>/dev/null)
if [[ -z "$PASS" ]]; then
  echo "No truenas-sudo in keychain. See scripts/credentials/README.md" >&2
  echo "" >&2
  echo "To verify Authelia config manually:" >&2
  echo "  1. TrueNAS → Apps → Installed → authelia → Edit → note the Host Path for the config volume." >&2
  echo "  2. In that path, edit configuration.yml. Ensure session.cookies has:" >&2
  echo "     authelia_url: https://sso.xcvr.link" >&2
  echo "     default_redirection_url: https://sso.xcvr.link" >&2
  echo "     domain: xcvr.link" >&2
  echo "  3. Restart Authelia (Stop → Start)." >&2
  echo "  Reference: docs/truenas/authelia-session-config-reference.yml" >&2
  exit 1
fi

echo "Finding Authelia configuration.yml on $TRUENAS_HOST..."
CONF=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
  "echo -n '$PASS' | sudo -S find /mnt/tank/apps /var/db/ix-applications /mnt -maxdepth 5 -name 'configuration.yml' -type f 2>/dev/null" | head -1)
if [[ -z "$CONF" ]]; then
  echo "Could not find configuration.yml under common paths." >&2
  echo "Find the config path in TrueNAS: Apps → authelia → Edit → Volume Mounts (path to /config)." >&2
  echo "Reference: docs/truenas/authelia-session-config-reference.yml" >&2
  exit 1
fi

echo "Found: $CONF"
echo ""
echo "--- session and server (relevant for sso.xcvr.link) ---"
ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
  "echo -n '$PASS' | sudo -S cat '$CONF' 2>/dev/null" | awk '
  /^server:/ { in_server=1 }
  in_server { print; if (/^[a-z]/ && !/^server/) in_server=0 }
  /^session:/ { in_session=1 }
  in_session { print; if (/^[a-z]/ && !/^session/) in_session=0 }
'
echo ""
echo "Compare with: docs/truenas/authelia-session-config-reference.yml"

#!/usr/bin/env bash
# Set TrueNAS system timezone to America/Chicago via SSH (midclt).
# Logs and UI will show Chicago time.
#
# Usage: ./scripts/truenas/set-timezone-chicago.sh
#
# Requires: SSH key to truenas_admin@TRUENAS_HOST (see scripts/credentials/README.md).

set -e

TRUENAS_HOST="${TRUENAS_HOST:-192.168.0.158}"
TRUENAS_USER="${TRUENAS_USER:-truenas_admin}"
TZ="${TZ:-America/Chicago}"

echo "Setting timezone to $TZ on $TRUENAS_USER@$TRUENAS_HOST..."
out=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
  "midclt call system.general.update '{\"timezone\": \"$TZ\"}'" 2>&1)
if echo "$out" | grep -q "\"timezone\": \"$TZ\""; then
  echo "Timezone set to $TZ."
else
  echo "$out" >&2
  exit 1
fi

#!/usr/bin/env bash
# Add xcvr.link local DNS records to UDM Pro via SSH
#
# Uses ubios-udapi-client on the UDM Pro to add host records to dnsForwarder.
# Requires: unifi/.env with UNIFI_SSH_USER, UNIFI_SSH_HOST, and optionally UNIFI_SSH_PASSWORD
#
# Records added (Caddy on Pi 5 replaces NPM+; see docs/networking/caddy-pi5-replace-npm.md):
#   sso, nas, headscale, rules, immich, n8n, syncthing, jellyfin, music → 192.168.0.136 (Caddy on Pi 5)
#   listen, watch, read → 192.168.0.136 (optional; for LAN resolution)
#   pi5 → 192.168.0.136
#   jet → 192.168.0.197

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: $ENV_FILE not found. Copy from .env.example and fill in SSH credentials."
  exit 1
fi

# shellcheck source=/dev/null
source "$ENV_FILE"

: "${UNIFI_SSH_USER:=root}"
: "${UNIFI_SSH_HOST:=192.168.0.1}"

# Records: hostname.domain → IP (proxied hosts → Caddy on Pi 5)
RECORDS=(
  "sso.xcvr.link:192.168.0.136"
  "nas.xcvr.link:192.168.0.136"
  "headscale.xcvr.link:192.168.0.136"
  "rules.xcvr.link:192.168.0.136"
  "immich.xcvr.link:192.168.0.136"
  "n8n.xcvr.link:192.168.0.136"
  "syncthing.xcvr.link:192.168.0.136"
  "pi5.xcvr.link:192.168.0.136"
  "jellyfin.xcvr.link:192.168.0.136"
  "music.xcvr.link:192.168.0.136"
  "listen.xcvr.link:192.168.0.136"
  "watch.xcvr.link:192.168.0.136"
  "read.xcvr.link:192.168.0.136"
  "jet.xcvr.link:192.168.0.197"
  "politics.xcvr.link:192.168.0.136"
)

# Remote script: add records via ubios-udapi-client + Python (no jq required)
# Uses $TMP_JSON and $RECORDS from environment
read -r -d '' REMOTE_SCRIPT << 'REMOTE_EOF' || true
TMP_JSON="/tmp/dns-update-$$.json"

if ! command -v ubios-udapi-client >/dev/null 2>&1; then
  echo "Error: ubios-udapi-client not found on UDM Pro. This script requires UniFi OS."
  exit 1
fi

echo "Fetching current DNS config..."
ubios-udapi-client GET -r /services > "$TMP_JSON" 2>/dev/null || {
  echo "Error: Failed to GET /services. Check UniFi OS version."
  exit 1
}

python3 - "$TMP_JSON" "$RECORDS" << 'PYEOF'
import json, sys, os
tmp_path = sys.argv[1]
records_str = sys.argv[2] if len(sys.argv) > 2 else ""

with open(tmp_path) as f:
    data = json.load(f)

if "dnsForwarder" not in data:
    data["dnsForwarder"] = {}
if "hostRecords" not in data["dnsForwarder"]:
    data["dnsForwarder"]["hostRecords"] = []

hr = data["dnsForwarder"]["hostRecords"]
existing = {r["hostName"].lower(): r for r in hr}

for pair in records_str.split(";"):
    pair = pair.strip()
    if not pair:
        continue
    parts = pair.split(":", 1)
    if len(parts) != 2:
        continue
    hostname, ip = parts[0].strip(), parts[1].strip()
    hostname_lower = hostname.lower()
    rec = {
        "address": {"address": ip, "origin": None, "version": "v4"},
        "hostName": hostname,
        "registerNonQualified": True
    }
    existing[hostname_lower] = rec
    print("  + " + hostname + " -> " + ip)

data["dnsForwarder"]["hostRecords"] = list(existing.values())

with open(tmp_path, "w") as f:
    json.dump(data, f, indent=2)
PYEOF

echo "Applying DNS records..."
ubios-udapi-client PUT /services "@$TMP_JSON" >/dev/null 2>&1 || {
  echo "Error: Failed to PUT /services. Config may be invalid."
  rm -f "$TMP_JSON"
  exit 1
}

rm -f "$TMP_JSON"
echo "Done. DNS records applied."
REMOTE_EOF

# Build records string for remote
RECORDS_STR=$(IFS=';'; echo "${RECORDS[*]}")

# Build SSH command
SSH_OPTS=(-o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new)
if [[ -n "$UNIFI_SSH_PASSWORD" ]]; then
  if command -v sshpass >/dev/null 2>&1; then
    SSH_CMD=(sshpass -e ssh "${SSH_OPTS[@]}")
  else
    echo "Warning: UNIFI_SSH_PASSWORD set but sshpass not installed. Install with: brew install sshpass"
    echo "Or use SSH key auth and leave UNIFI_SSH_PASSWORD empty."
    SSH_CMD=(ssh "${SSH_OPTS[@]}")
  fi
  export SSHPASS="$UNIFI_SSH_PASSWORD"
else
  SSH_CMD=(ssh "${SSH_OPTS[@]}")
fi

echo "Adding local DNS records to UDM Pro at $UNIFI_SSH_HOST..."
echo "Records: ${RECORDS[*]}"
echo ""

# Run remote: pass RECORDS as env var (single line, semicolon-separated)
"${SSH_CMD[@]}" "$UNIFI_SSH_USER@$UNIFI_SSH_HOST" "RECORDS='$RECORDS_STR' $REMOTE_SCRIPT"

echo ""
echo "Verify with: dig +short sso.xcvr.link @$UNIFI_SSH_HOST"
echo "             dig +short music.xcvr.link @$UNIFI_SSH_HOST"
echo "(Ensure your Mac uses UDM Pro DNS: 192.168.0.1)"

#!/usr/bin/env bash
# Set Headscale DNS to use the router (UDM Pro 192.168.0.1) so Tailscale DNS
# uses UniFi Local DNS for *.xcvr.link. Runs from your Mac via SSH to the NAS.
#
# Usage: ./scripts/truenas/headscale-set-dns-router.sh
#
# Requires: same as headscale-remote.sh — SSH key to truenas_admin@TRUENAS_HOST,
# and keychain "truenas-sudo". See scripts/credentials/README.md.
#
# Note: The TrueNAS Headscale app chart may not expose nameservers via midclt
# (EINVAL "Field was not expected"). If so, set manually: Apps → headscale → Edit
# → DNS / Nameservers → Global: 192.168.0.1.

set -e

TRUENAS_HOST="${TRUENAS_HOST:-192.168.0.158}"
TRUENAS_USER="${TRUENAS_USER:-truenas_admin}"
ROUTER_DNS="${ROUTER_DNS:-192.168.0.1}"
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
  exit 1
fi

# midclt app.update payload: set Headscale global nameservers to router
# Escaped for ssh + sudo -S; JSON must be valid on the remote side.
PAYLOAD="{\"values\": {\"headscale\": {\"dns\": {\"nameservers\": {\"global\": [\"$ROUTER_DNS\"]}}}}}"

echo "Setting Headscale DNS nameservers.global to $ROUTER_DNS (router) on NAS..."
ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
  "echo -n '$PASS' | sudo -S midclt call -j app.update headscale '$PAYLOAD'" 2>&1 | grep -v "password for truenas_admin" || true
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
  echo "SSH or midclt failed. Set manually: TrueNAS → Apps → headscale → Edit → DNS / Nameservers → Global: $ROUTER_DNS"
  echo "See: docs/networking/headscale-xcvr-dns-seamless.md § Direct Tailscale DNS to use the router"
  exit 1
fi
echo "Update submitted. Headscale app may redeploy; then Tailscale clients will use $ROUTER_DNS for DNS."

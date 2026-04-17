#!/usr/bin/env bash
# Generate OIDC client secrets for Immich, Headscale, Jellyfin and deploy Authelia config.
# Replaces REPLACE_*_CLIENT_SECRET placeholders. Run before configuring OIDC in each app.
#
# Usage: ./scripts/truenas/authelia-set-oidc-secrets.sh
#   Generates secrets, prints them, deploys config with secrets substituted.
#
# Optional env vars (if you already have secrets):
#   AUTHELIA_OIDC_IMMICH_SECRET, AUTHELIA_OIDC_HEADSCALE_SECRET, AUTHELIA_OIDC_JELLYFIN_SECRET
#
# After running: copy each secret into Immich (Admin → OAuth), Headscale config, Jellyfin SSO plugin.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Generate or use existing
IMMICH="${AUTHELIA_OIDC_IMMICH_SECRET:-$(openssl rand -base64 32)}"
HEADSCALE="${AUTHELIA_OIDC_HEADSCALE_SECRET:-$(openssl rand -base64 32)}"
JELLYFIN="${AUTHELIA_OIDC_JELLYFIN_SECRET:-$(openssl rand -base64 32)}"

export AUTHELIA_OIDC_IMMICH_SECRET="$IMMICH"
export AUTHELIA_OIDC_HEADSCALE_SECRET="$HEADSCALE"
export AUTHELIA_OIDC_JELLYFIN_SECRET="$JELLYFIN"

echo "=== OIDC Client Secrets (copy into each app) ==="
echo ""
echo "Immich (Admin → OAuth → OID Client Secret):"
echo "  $IMMICH"
echo ""
echo "Headscale (config oidc.client_secret):"
echo "  $HEADSCALE"
echo ""
echo "Jellyfin SSO plugin (OID Secret):"
echo "  $JELLYFIN"
echo ""
echo "Deploying Authelia config with these secrets..."
echo ""

exec "$SCRIPT_DIR/authelia-deploy-config.sh" "$@"

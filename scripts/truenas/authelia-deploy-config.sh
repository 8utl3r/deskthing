#!/usr/bin/env bash
# Deploy fixed configuration.yml and users_database.yml to Authelia's Config Storage on TrueNAS.
# Fixes fatal config errors (users in wrong file, missing cookies/notifier/auth_backend/rules).
# Config path: /mnt/.ix-apps/app_mounts/authelia/config (TrueNAS 24.10+ ix-apps; see apps.truenas.com/getting-started/app-storage).
# Run from Mac. Requires: truenas-sudo in keychain, SSH to truenas_admin@TRUENAS_HOST.
#
# Scp is run with a 90s timeout. If coreutils is installed (Brewfile: brew "coreutils"), the script uses gtimeout; otherwise it falls back to a background-kill timeout. No extra steps needed—just run the script.
#
# Usage: ./scripts/truenas/authelia-deploy-config.sh
# OIDC secrets: ./scripts/truenas/authelia-set-oidc-secrets.sh (generates + deploys)
# Rich dashboard: python3 scripts/truenas/authelia-dashboard.py [--plain]

set -e

TRUENAS_HOST="${TRUENAS_HOST:-192.168.0.158}"
TRUENAS_USER="${TRUENAS_USER:-truenas_admin}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_EXAMPLE="$DOTFILES_ROOT/docs/truenas/authelia-configuration-yml-full-example.yml"
USERS_EXAMPLE="$DOTFILES_ROOT/docs/truenas/authelia-users-database-yml-example.yml"
CREDS_SH="${CREDS_SH:-$HOME/dotfiles/scripts/credentials/creds.sh}"
DBG() { echo "[authelia-deploy] $*"; }

DBG "start: TRUENAS_HOST=$TRUENAS_HOST TRUENAS_USER=$TRUENAS_USER USERS_FILE=${USERS_FILE:-<unset>}"

echo "Checking source files..."
for f in "$CONFIG_EXAMPLE" "$USERS_EXAMPLE"; do
  if [[ ! -f "$f" ]]; then
    echo "Error: missing $f" >&2
    exit 1
  fi
done

# Ensure source config contains OIDC clients (immich, headscale, jellyfin) so we never deploy placeholder-only config
if ! grep -q "client_id: immich" "$CONFIG_EXAMPLE"; then
  echo "Error: $CONFIG_EXAMPLE does not contain 'client_id: immich'. Refusing to deploy (wrong or old example)." >&2
  exit 1
fi
echo "Using config source: $CONFIG_EXAMPLE"

echo "Loading credentials..."
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
echo "Credentials loaded."

# Filter noise from SSH/sudo (keychain prompt, sudo password line)
_filter_ssh() { grep -v "bleep blorp" | grep -v "\[sudo\] password for"; }

# Run a command with 90s timeout; set SCP_EXIT. Prefers gtimeout (brew install coreutils).
# Scp is run without piping stderr (redirect to temp file) so it doesn't hang when run non-interactively.
_run_with_timeout() {
  local cmd=("$@")
  local timeout_cmd=""
  local tmp_err
  tmp_err=$(mktemp)
  trap 'rm -f "$tmp_err"' RETURN
  # Prefer gtimeout from coreutils (dotfiles Brewfile: brew "coreutils")
  if command -v gtimeout &>/dev/null; then
    timeout_cmd="gtimeout"
  elif command -v timeout &>/dev/null; then
    timeout_cmd="timeout"
  fi
  if [[ -n "$timeout_cmd" ]]; then
    $timeout_cmd 90 "${cmd[@]}" 2> "$tmp_err"
    SCP_EXIT=$?
    [[ -s "$tmp_err" ]] && cat "$tmp_err" | _filter_ssh
    [[ $SCP_EXIT -eq 124 ]] && DBG "scp timed out after 90s ($timeout_cmd)"
    return 0
  fi
  # Fallback: no coreutils/timeout—run in background and kill after 90s (exit code may be wrong on success)
  DBG "gtimeout not found (install coreutils: brew install coreutils); using 90s background kill"
  ("${cmd[@]}" 2> "$tmp_err"; echo $? > "$tmp_err.exit") &
  local pid=$!
  local i=0
  while kill -0 "$pid" 2>/dev/null && [[ $i -lt 90 ]]; do sleep 1; i=$((i+1)); done
  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
    SCP_EXIT=124
    DBG "scp timed out after 90s (bash kill)"
  else
    wait "$pid"
    SCP_EXIT=$(cat "$tmp_err.exit" 2>/dev/null || 0)
  fi
  [[ -s "$tmp_err" ]] && cat "$tmp_err" | _filter_ssh
  rm -f "$tmp_err.exit"
  return 0
}

echo "Finding Authelia Config Storage on $TRUENAS_HOST..."
CONF_DIR_DEFAULT="/mnt/.ix-apps/app_mounts/authelia/config"
DBG "running: ssh find configuration.yml..."
CONF_PATH=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
  "echo -n '$PASS' | sudo -S find /mnt/.ix-apps /mnt/tank /var/db -name 'configuration.yml' -type f 2>/dev/null" 2>&1 | _filter_ssh | head -1)
DBG "ssh find exit (via PIPESTATUS): ${PIPESTATUS[0]}, CONF_PATH=${CONF_PATH:-(empty)}"

if [[ -n "$CONF_PATH" ]]; then
  CONF_DIR="${CONF_PATH%/*}"
  DBG "CONF_DIR from find: $CONF_DIR"
else
  DBG "find returned nothing, testing default dir $CONF_DIR_DEFAULT..."
  ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
    "echo -n '$PASS' | sudo -S test -d '$CONF_DIR_DEFAULT'" 2>&1 | _filter_ssh >/dev/null
  SSH_EXIT=${PIPESTATUS[0]}
  DBG "ssh test -d exit: $SSH_EXIT"
  if [[ $SSH_EXIT -eq 0 ]]; then
    CONF_DIR="$CONF_DIR_DEFAULT"
  else
    echo "Could not find Authelia config directory on NAS." >&2
    echo "Try: TrueNAS Shell, then: sudo find /mnt -name 'configuration.yml' -o -path '*authelia*config*' -type d 2>/dev/null" >&2
    exit 1
  fi
fi
echo "Using config directory: $CONF_DIR"
echo "Config path resolved."

DEPLOY_USERS="yes"
if [[ -z "${USERS_FILE:-}" ]]; then
  echo "Checking for existing users_database.yml on NAS..."
  ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
    "echo -n '$PASS' | sudo -S test -f '$CONF_DIR/data/users_database.yml'" 2>&1 | _filter_ssh >/dev/null
  SSH_EXIT=${PIPESTATUS[0]}
  DBG "ssh test -f users_database.yml exit: $SSH_EXIT"
  if [[ $SSH_EXIT -eq 0 ]]; then
    DEPLOY_USERS="no"
    echo "Keeping existing users_database.yml on NAS (set USERS_FILE to replace)."
  fi
fi
DBG "DEPLOY_USERS=$DEPLOY_USERS"
echo "Users file decision done."

echo "Generating configuration.yml (HMAC, OIDC key, secrets)..."
# Generate OIDC hmac_secret and a valid RSA key so config parses (4.38+ requires valid PEM)
HMAC=$(openssl rand -base64 32)
OIDC_KEY_FILE=$(mktemp)
trap 'rm -f "$OIDC_KEY_FILE"' EXIT

# OIDC client secrets: use env vars if set (e.g. from authelia-set-oidc-secrets.sh), else leave placeholders
IMMICH_SECRET="${AUTHELIA_OIDC_IMMICH_SECRET:-REPLACE_IMMICH_CLIENT_SECRET}"
HEADSCALE_SECRET="${AUTHELIA_OIDC_HEADSCALE_SECRET:-REPLACE_HEADSCALE_CLIENT_SECRET}"
JELLYFIN_SECRET="${AUTHELIA_OIDC_JELLYFIN_SECRET:-REPLACE_JELLYFIN_CLIENT_SECRET}"

if ! openssl genrsa 4096 2>/dev/null > "$OIDC_KEY_FILE"; then
  echo "Warning: could not generate RSA key; REPLACE_ISSUER_PRIVATE_KEY will remain and may cause startup errors." >&2
  sed -e "s|REPLACE_HMAC_SECRET|$HMAC|" \
      -e "s|REPLACE_IMMICH_CLIENT_SECRET|$IMMICH_SECRET|" \
      -e "s|REPLACE_HEADSCALE_CLIENT_SECRET|$HEADSCALE_SECRET|" \
      -e "s|REPLACE_JELLYFIN_CLIENT_SECRET|$JELLYFIN_SECRET|" \
      "$CONFIG_EXAMPLE" > /tmp/authelia-configuration.yml
else
  # Replace placeholders; issuer_private_key must be a multi-line YAML block (|)
  awk -v hmac="$HMAC" -v keyfile="$OIDC_KEY_FILE" \
      -v immich="$IMMICH_SECRET" -v headscale="$HEADSCALE_SECRET" -v jellyfin="$JELLYFIN_SECRET" '
    /REPLACE_HMAC_SECRET/ { gsub(/REPLACE_HMAC_SECRET/, hmac); print; next }
    /REPLACE_IMMICH_CLIENT_SECRET/ { gsub(/REPLACE_IMMICH_CLIENT_SECRET/, immich); print; next }
    /REPLACE_HEADSCALE_CLIENT_SECRET/ { gsub(/REPLACE_HEADSCALE_CLIENT_SECRET/, headscale); print; next }
    /REPLACE_JELLYFIN_CLIENT_SECRET/ { gsub(/REPLACE_JELLYFIN_CLIENT_SECRET/, jellyfin); print; next }
    /REPLACE_ISSUER_PRIVATE_KEY/ {
      print "    issuer_private_key: |"
      while ((getline line < keyfile) > 0) print "      " line
      close(keyfile)
      next
    }
    { print }
  ' "$CONFIG_EXAMPLE" > /tmp/authelia-configuration.yml
fi
echo "Generated /tmp/authelia-configuration.yml."

# Verify generated config contains OIDC clients before deploying
echo "Verifying generated config contains immich client..."
if ! grep -q "client_id: immich" /tmp/authelia-configuration.yml; then
  echo "Error: Generated config missing 'client_id: immich'. Refusing to deploy." >&2
  exit 1
fi
echo "Generated config OK."

echo "Preparing users_database.yml..."
if [[ -n "${USERS_FILE:-}" && -f "${USERS_FILE}" ]]; then
  cp "$USERS_FILE" /tmp/authelia-users_database.yml
else
  cp "$USERS_EXAMPLE" /tmp/authelia-users_database.yml
fi
echo "Users file prepared."

echo "Copying configuration.yml (and users_database.yml) to NAS..."
SCP_EXIT=0
if [[ "$DEPLOY_USERS" = "yes" ]]; then
  DBG "scp: config + users_database to $TRUENAS_USER@$TRUENAS_HOST:/tmp/ (90s timeout)"
  _run_with_timeout scp -o ConnectTimeout=10 -o BatchMode=yes -o LogLevel=ERROR /tmp/authelia-configuration.yml /tmp/authelia-users_database.yml "$TRUENAS_USER@$TRUENAS_HOST:/tmp/"
  DBG "scp exit: $SCP_EXIT"
  [[ $SCP_EXIT -eq 0 ]] || { echo "Error: scp to NAS failed (exit $SCP_EXIT). Check SSH (e.g. ssh $TRUENAS_USER@$TRUENAS_HOST) and that /tmp is writable. Exit 124 = timed out after 90s." >&2; exit 1; }
else
  DBG "scp: config only to $TRUENAS_USER@$TRUENAS_HOST:/tmp/ (90s timeout)"
  _run_with_timeout scp -o ConnectTimeout=10 -o BatchMode=yes -o LogLevel=ERROR /tmp/authelia-configuration.yml "$TRUENAS_USER@$TRUENAS_HOST:/tmp/"
  DBG "scp exit: $SCP_EXIT"
  [[ $SCP_EXIT -eq 0 ]] || { echo "Error: scp to NAS failed (exit $SCP_EXIT). Check SSH and /tmp. Exit 124 = timed out after 90s." >&2; exit 1; }
fi
echo "Uploaded to /tmp/. Writing to config directory..."

# Put users_database.yml in data/ subdir so Authelia does not merge it (when config is a dir, all .yml in that dir are merged; users: in main config is forbidden in 4.38+)
DBG "ssh: mkdir/cp/chown/chmod/rm on NAS ($CONF_DIR)..."
SSH_OUT=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
  "echo -n '$PASS' | sudo -S sh -c '\
   mkdir -p \"$CONF_DIR/data\" && \
   cp /tmp/authelia-configuration.yml \"$CONF_DIR/configuration.yml\" && \
   if [ \"$DEPLOY_USERS\" = \"yes\" ]; then cp /tmp/authelia-users_database.yml \"$CONF_DIR/data/users_database.yml\"; fi && \
   chown -R 568:568 \"$CONF_DIR/data\" && \
   chmod 755 \"$CONF_DIR/data\" && \
   chmod 644 \"$CONF_DIR/data/users_database.yml\" 2>/dev/null || true && \
   chmod -R o+rX \"$CONF_DIR/data\" && \
   rm -f /tmp/authelia-configuration.yml /tmp/authelia-users_database.yml'" 2>&1 | _filter_ssh)
SSH_EXIT=${PIPESTATUS[0]}
DBG "ssh mkdir/cp/chown exit: $SSH_EXIT"
if [[ -n "$SSH_OUT" ]]; then
  DBG "ssh stderr/stdout: $SSH_OUT"
fi
if [[ $SSH_EXIT -ne 0 ]]; then
  echo "Error: failed to write configuration.yml to $CONF_DIR on NAS (sudo cp/chown, exit $SSH_EXIT). Check path and sudo on NAS." >&2
  exit 1
fi
echo "Wrote configuration.yml to config directory."

echo "Removing other YAML from config root..."
# Remove ALL other YAML files from config root so only configuration.yml is loaded (TrueNAS chart may inject files with users: that get merged)
ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
  "echo -n '$PASS' | sudo -S sh -c 'for f in \"$CONF_DIR\"/*.yml \"$CONF_DIR\"/*.yaml; do [ -f \"\$f\" ] || continue; b=\$(basename \"\$f\"); [ \"\$b\" = configuration.yml ] || [ \"\$b\" = configuration.yaml ] || rm -f \"\$f\"; done'" 2>&1 | _filter_ssh
DBG "ssh rm other yaml exit: ${PIPESTATUS[0]}"
[[ ${PIPESTATUS[0]} -eq 0 ]] || { echo "Error: failed to remove other YAML from config root on NAS." >&2; exit 1; }
echo "Other YAML removed."

echo "Cleaning local /tmp files..."
rm -f /tmp/authelia-configuration.yml /tmp/authelia-users_database.yml
DBG "local /tmp cleaned"
echo "Local /tmp cleaned."

# Verify deployed file on NAS contains immich client (cat back and check)
echo "Verifying deployed file on NAS contains immich client..."
DEPLOYED_CHECK=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
  "echo -n '$PASS' | sudo -S grep -l 'client_id: immich' '$CONF_DIR/configuration.yml' 2>/dev/null" 2>&1 | _filter_ssh)
DBG "ssh grep verify exit: ${PIPESTATUS[0]}, DEPLOYED_CHECK=${DEPLOYED_CHECK:-(empty)}"
if [[ -z "$DEPLOYED_CHECK" ]]; then
  echo "Error: After deploy, '$CONF_DIR/configuration.yml' on NAS does not contain 'client_id: immich'." >&2
  echo "Authelia may be reading a different path or the write did not take effect." >&2
  exit 1
fi
echo "Verified: deployed configuration.yml contains immich client."

# Show OIDC client_id/client_name lines from deployed file (confirms what is on disk this instant)
echo "Reading OIDC clients from deployed configuration.yml on NAS..."
echo "OIDC clients now in $CONF_DIR/configuration.yml on NAS:"
ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
  "echo -n '$PASS' | sudo -S grep -E '^\s*(client_id|client_name):' '$CONF_DIR/configuration.yml' 2>/dev/null" 2>&1 | _filter_ssh | sed 's/^/  /'
DBG "ssh grep OIDC exit: ${PIPESTATUS[0]}"

# Diagnostic: file mtime so we can confirm the file we wrote is the one on disk (and not reverted later)
CONF_MTIME=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
  "echo -n '$PASS' | sudo -S stat -c '%y' '$CONF_DIR/configuration.yml' 2>/dev/null" 2>&1 | _filter_ssh | head -1)
DBG "config mtime ssh exit: ${PIPESTATUS[0]}"
[[ -n "$CONF_MTIME" ]] && echo "Config file mtime on NAS: $CONF_MTIME (if this is old after you deploy, something overwrote it)."

DBG "all steps completed successfully"
echo ""
echo "Done. Next steps:"
if [[ -z "${USERS_FILE:-}" ]]; then
  echo "  1. Fix users: the deployed users_database.yml has placeholder 'your_username' and an invalid hash, so Authelia will not start (argon2 decode error)."
  echo "     Easiest: ./scripts/truenas/authelia-setup-with-docker.sh <your_username>  (generates hash + deploys valid users file; requires Docker on Mac)"
  echo "     Or: ./scripts/truenas/authelia-hash-password.sh to get a hash, then edit $CONF_DIR/data/users_database.yml on the NAS (replace your_username and the password line)."
  echo "  2. Restart Authelia: TrueNAS → Apps → authelia → Stop → Start"
else
  echo "  1. Restart Authelia: TrueNAS → Apps → authelia → Stop → Start"
fi
echo ""
echo "If Immich still shows 'client immich not registered':"
echo "  - Above you must see 'client_id: immich' in the OIDC clients list. If you only see forward_auth_placeholder, the chart may be overwriting; uncheck 'Use Dummy Configuration' (Apps → authelia → Edit → Authelia Configuration → Update), then run this script again."
echo "  - After deploy, restart Authelia so it reloads configuration.yml."
echo "  - If the OIDC list shows immich now but after restart the file on NAS reverts to placeholder, run this deploy again after each restart (see docs/truenas/authelia-config-persistence.md)."
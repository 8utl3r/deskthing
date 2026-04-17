#!/usr/bin/env bash
# Prompt for a password and output an Argon2 hash for use in Authelia users_database.yml.
# Usage: ./scripts/truenas/authelia-hash-password.sh
#
# Tries, in order: (1) local 'authelia' CLI in PATH, (2) existing Authelia container on
# TrueNAS (SSH + docker exec — no Docker on your Mac), (3) local Docker one-off container.
# Passwords with $, ", \, or newlines are passed via stdin where possible.

set -e

TRUENAS_HOST="${TRUENAS_HOST:-192.168.0.158}"
TRUENAS_USER="${TRUENAS_USER:-truenas_admin}"
CREDS_SH="${CREDS_SH:-$HOME/dotfiles/scripts/credentials/creds.sh}"

echo "Password for Authelia (input hidden):"
read -rs PASSWORD
echo

if [[ -z "$PASSWORD" ]]; then
  echo "No password entered." >&2
  exit 1
fi

DOCKER_ERR=$(mktemp)
trap 'rm -f "$DOCKER_ERR"' EXIT
: > "$DOCKER_ERR"
HASH=""

# 1) Local Authelia CLI in PATH (if you install the binary)
if command -v authelia &>/dev/null; then
  HASH=$(printf '%s' "$PASSWORD" | authelia crypto hash generate argon2 2>>"$DOCKER_ERR") || true
  is_hash "$HASH" || HASH=""
fi

# Only treat output as hash if it looks like Argon2 (avoid NAS/Docker error lines).
is_hash() { [[ "$1" =~ ^\$argon2 ]]; }

# 2) NAS: exec into the running Authelia container (no Docker on Mac needed).
#    Send: one line = sudo password, rest = user password for authelia CLI.
#    Set AUTHELIA_CONTAINER to the container name if discovery fails.
if [[ -z "$HASH" ]] && [[ -f "${CREDS_SH:-}" ]]; then
  source "$CREDS_SH" 2>/dev/null || true
  PASS=$(creds_get truenas-sudo 2>/dev/null)
  if [[ -n "$PASS" ]]; then
    HASH=$(printf '%s\n%s' "$PASS" "$PASSWORD" | ssh -o ConnectTimeout=10 -o BatchMode=yes "$TRUENAS_USER@$TRUENAS_HOST" \
      "export AUTHELIA_CONTAINER='${AUTHELIA_CONTAINER:-}';
       read -r SUDO_PASS;
       CONTAINER=\"\$AUTHELIA_CONTAINER\";
       if [ -z \"\$CONTAINER\" ]; then CONTAINER=\$(echo -n \"\$SUDO_PASS\" | sudo -S docker ps -q --filter name=authelia 2>&1 | head -1); fi;
       if [ -n \"\$CONTAINER\" ]; then echo -n \"\$SUDO_PASS\" | sudo -S sh -c \"cat | docker exec -i \\\"\$CONTAINER\\\" authelia crypto hash generate argon2\" 2>&1; fi" 2>>"$DOCKER_ERR") || true
    is_hash "$HASH" || HASH=""
    unset PASS
  fi
fi

# 3) Local Docker one-off container (fallback)
if [[ -z "$HASH" ]]; then
  HASH=$(printf '%s' "$PASSWORD" | docker run --rm -i authelia/authelia:latest authelia crypto hash generate argon2 2>>"$DOCKER_ERR") || true
  is_hash "$HASH" || HASH=""
fi

unset PASSWORD

if [[ -z "$HASH" ]]; then
  echo "Failed to generate hash." >&2
  if [[ -s "$DOCKER_ERR" ]]; then
    echo "Error:" >&2
    cat "$DOCKER_ERR" >&2
  fi
  echo "" >&2
  echo "Tried: (1) authelia in PATH, (2) NAS container via SSH to $TRUENAS_HOST, (3) local Docker." >&2
  echo "If NAS was used: on the NAS, 'docker' may not be in PATH or the Authelia container name may differ." >&2
  echo "To inspect on NAS: ssh $TRUENAS_USER@$TRUENAS_HOST 'echo PASSPHRASE | sudo -S docker ps' (or sudo -S ctr -n ix containers list)." >&2
  exit 1
fi

echo ""
echo "Argon2 hash (paste this into users_database.yml for your user):"
echo ""
echo "$HASH"
echo ""

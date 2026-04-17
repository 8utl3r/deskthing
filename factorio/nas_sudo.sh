#!/bin/bash
# Run a command with sudo on the NAS. Password is read from NAS_SUDO_PASSWORD.
# Usage: NAS_SUDO_PASSWORD=yourpass ./nas_sudo.sh 'docker ps -a'
#        Or: create factorio/.env.nas (gitignored) with one line, e.g.:
#            NAS_SUDO_PASSWORD='12345678'
#        Then: ./nas_sudo.sh docker ps -a
# Do not commit the password.

set -e
cd "$(dirname "$0")"
[ -f .env.nas ] && set -a && source .env.nas && set +a

NAS="${NAS_USER:-truenas_admin}@${NAS_HOST:-192.168.0.158}"

if [ -z "${NAS_SUDO_PASSWORD:-}" ]; then
  echo "NAS_SUDO_PASSWORD is not set. Create factorio/.env.nas with one line, e.g.:"
  echo "  NAS_SUDO_PASSWORD='12345678'"
  echo "Then run: $0 '<command>'"
  exit 1
fi

if [ $# -eq 0 ]; then
  set -- docker ps -a
fi
echo "$NAS_SUDO_PASSWORD" | ssh -o BatchMode=yes "$NAS" "sudo -S $*"

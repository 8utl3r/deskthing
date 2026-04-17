#!/usr/bin/env bash
# Create TRaSH-style data layout for Servarr stack on Pi 5.
# Run on the Pi once (e.g. after first boot from NVMe).
# Usage: sudo bash servarr-pi5-create-data-dirs.sh [BASE_DIR]
# Default BASE_DIR: /mnt/data

set -e
BASE="${1:-/mnt/data}"

echo "Creating Servarr data layout under ${BASE}"

mkdir -p "${BASE}/torrents"/{movies,tv,music,books,audiobooks}
mkdir -p "${BASE}/media"/{movies,tv,music,books,audiobooks}

# If BASE is not on a separate mount, use current user for ownership.
# If you mount a USB drive at BASE, run chown after mounting.
OWNER="${SUDO_USER:-$USER}"
chown -R "${OWNER}:${OWNER}" "${BASE}"

echo "Done. Layout:"
ls -la "${BASE}"
ls -la "${BASE}/torrents"
ls -la "${BASE}/media"

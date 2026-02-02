#!/usr/bin/env bash
# Apply DeskThing log-issue fixes to settings.json.
# Run once; restart DeskThing after.
# Usage: ./car-thing/scripts/fix-deskthing-settings.sh

set -e

SETTINGS="$HOME/Library/Application Support/deskthing/settings.json"

if [[ ! -f "$SETTINGS" ]]; then
  echo "DeskThing settings not found: $SETTINGS"
  exit 1
fi

# Device that fails with /etc/superbird/version errors (not Thing Labs firmware)
BLACKLIST_DEVICE="${1:-RFCWC0PXXYV}"

echo "Applying fixes to $SETTINGS"
echo "  1. Add $BLACKLIST_DEVICE to adb_blacklist (skip problematic device)"
echo "  2. Set flag_collectStats = false (stop 403 stats registration)"

# Use node for reliable JSON edit
if ! command -v node &>/dev/null; then
  echo "Node required for JSON edit. Install Node or apply manually."
  exit 1
fi

SETTINGS_ESC="${SETTINGS//\'/\\\'}"
node -e "
const fs = require('fs');
const path = process.env.DESKTHING_SETTINGS;
let s = JSON.parse(fs.readFileSync(path, 'utf8'));

// Add device to blacklist if not present
const device = process.env.BLACKLIST_DEVICE;
s.adb_blacklist = s.adb_blacklist || [];
if (!s.adb_blacklist.includes(device)) {
  s.adb_blacklist.push(device);
  console.log('Added ' + device + ' to adb_blacklist');
} else {
  console.log(device + ' already in adb_blacklist');
}

// Disable stats (stops 403 Forbidden)
s.flag_collectStats = false;
console.log('Set flag_collectStats = false');

fs.writeFileSync(path, JSON.stringify(s, null, 2));
" DESKTHING_SETTINGS="$SETTINGS" BLACKLIST_DEVICE="$BLACKLIST_DEVICE"

echo ""
echo "Done. Restart DeskThing for changes to take effect."

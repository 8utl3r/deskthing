#!/usr/bin/env bash
# Fix DeskThing device connection: blacklist problematic devices, reset ADB, restart DeskThing.
# Run when the device isn't connecting (e.g. errors for RFCWC0PXXYV in logs).
#
# Usage: ./car-thing/scripts/fix-device-connection.sh [--no-restart]
#   --no-restart  Apply fixes but don't restart DeskThing (you must restart manually)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CAR_THING_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== DeskThing device connection fix ==="
echo ""

# 1. Apply settings fix (blacklist Samsung phone RFCWC0PXXYV, disable stats)
"$CAR_THING_DIR/scripts/fix-deskthing-settings.sh"

echo ""
echo "Resetting ADB..."
adb kill-server 2>/dev/null || true
sleep 2
adb start-server
sleep 1
echo "Devices:"
adb devices
echo ""

if [[ "$1" == "--no-restart" ]]; then
  echo "Skipping DeskThing restart (--no-restart). Restart DeskThing manually for blacklist to take effect."
  exit 0
fi

echo "Restarting DeskThing..."
osascript -e 'quit app "DeskThing"' 2>/dev/null || true
sleep 2
open -a DeskThing
echo ""
echo "Done. DeskThing should now ignore RFCWC0PXXYV and connect to the Car Thing (8557R08RQ01Q)."

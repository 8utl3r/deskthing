#!/usr/bin/env bash
# Reset ADB and prompt to refresh DeskThing. Run when device isn't connecting.
# Usage: ./car-thing/scripts/reconnect-device.sh

set -e

echo "Car Thing: Resetting ADB connection..."
adb kill-server 2>/dev/null || true
sleep 2
adb start-server
sleep 1
echo ""
echo "Devices:"
adb devices
echo ""
echo "Next: Open DeskThing → Clients → Refresh ADB"
echo "If the device still doesn't appear, try:"
echo "  1. Unplug and replug the Car Thing USB cable"
echo "  2. On the device: Settings → Skip Setup (if prompted)"
echo "  3. DeskThing → Settings → Device → enable Auto Detect ADB, Use Global ADB"

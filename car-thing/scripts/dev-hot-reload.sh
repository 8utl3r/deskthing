#!/usr/bin/env bash
# Hot-reload setup for Car Thing app development.
# 1. Forwards Vite dev port (5173) to device via ADB reverse.
# 2. Run `npm run dev` in deskthing-app/ in another terminal.
# 3. On device: LiteClient → Settings → Dev Mode → Developer App → enter 5173.
#
# Prerequisites: LiteClient on device, USB connected, adb devices shows device.
set -e

# DeskThing dev server runs on 3000; Vite on 5173. LiteClient Dev Mode loads from 3000.
DEV_PORT=3000
VITE_PORT=5173

# Get first connected device (use adb devices without -l so line ends with "device")
DEVICE=$(adb devices | grep -E '\tdevice$' | head -1 | awk '{print $1}')
if [[ -z "$DEVICE" ]]; then
  echo "No ADB device found. Connect Car Thing via USB and run: adb devices"
  exit 1
fi

echo "Forwarding ports $DEV_PORT and $VITE_PORT to device $DEVICE..."
adb -s "$DEVICE" reverse tcp:$DEV_PORT tcp:$DEV_PORT
adb -s "$DEVICE" reverse tcp:$VITE_PORT tcp:$VITE_PORT
echo "Done."
echo ""
echo "Next:"
echo "  1. In another terminal: cd car-thing/deskthing-app && npm run dev"
echo "  2. On Car Thing: LiteClient → Settings → Dev Mode → Developer App"
echo "  3. Enter port: $DEV_PORT (not 5173)"
echo "  4. Edit and save for hot reload."

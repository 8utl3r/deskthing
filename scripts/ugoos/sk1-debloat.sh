#!/usr/bin/env bash
# Ugoos SK1 debloat - remove safe packages, record what was removed.
# Excludes: Obtainium, Jellyfin, Magisk (core to setup)
# Reversible: factory reset restores all.
# Output: docs/hardware/ugoos-sk1-debloat-removed.txt
# Run: adb connect 192.168.0.159:5555  # first

DEVICE="${SK1_DEVICE:-192.168.0.159:5555}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REMOVED_FILE="$DOTFILES_ROOT/docs/hardware/ugoos-sk1-debloat-removed.txt"
LOG_FILE="$DOTFILES_ROOT/docs/hardware/ugoos-sk1-debloat-log.txt"

PACKAGES=(
  com.android.chrome
  com.ghisler.tcplugins.LAN
  com.ghisler.android.TotalCommander
  com.ionitech.airscreen
  com.uapplication.uplayer
  com.google.android.backuptransport
  com.google.android.katniss
  com.google.android.tv.remote.service
  com.android.adservices.api
  com.android.ext.adservices.api
  com.android.ondevicepersonalization.services
  com.android.companiondevicemanager
  com.android.devicelockcontroller
  com.android.federatedcompute.services
  com.android.music
  com.android.musicfx
  com.android.dreams.phototable
  com.android.dreams.basic
  com.android.wallpaper.livepicker
  com.android.wallpaperbackup
  com.android.wallpapercropper
  com.android.gallery3d
  com.android.providers.contacts
  com.android.providers.calendar
  com.android.health.connect.backuprestore
  com.android.healthconnect.controller
  com.android.htmlviewer
  com.android.nearby.halfsheet
  com.android.printspooler
  com.android.deskclock
  com.android.camera2
  com.android.cameraextensions
  com.android.virtualmachine.res
  com.android.uwb.resources
  com.android.dynsystem
  com.android.hotspot2.osulogin
  com.android.localtransport
  com.android.sharedstoragebackup
  com.android.statementservice
  com.android.proxyhandler
  com.droidlogic.mediacenter
  com.droidlogic.imageplayer
  com.droidlogic.miracast
  com.droidlogic.FileBrower
  com.ugoos.autotest
  com.ugoos.ugoosfirstrun
)

echo "# Ugoos SK1 Debloat - Removed packages $(date -Iseconds)" > "$REMOVED_FILE"
echo "# Run: adb -s $DEVICE shell pm uninstall --user 0 <pkg>" >> "$REMOVED_FILE"
echo "# Factory reset restores all." >> "$REMOVED_FILE"
echo "" >> "$REMOVED_FILE"

{
  echo "=== Debloat run $(date -Iseconds) ==="
  echo "Device: $DEVICE"
  echo ""
} | tee "$LOG_FILE"

removed=0
failed=0

for pkg in "${PACKAGES[@]}"; do
  if out=$(adb -s "$DEVICE" shell pm uninstall --user 0 "$pkg" 2>&1); then
    if echo "$out" | grep -q "Success"; then
      echo "OK: $pkg" | tee -a "$LOG_FILE"
      echo "$pkg" >> "$REMOVED_FILE"
      removed=$((removed + 1))
    else
      echo "SKIP: $pkg (not installed?)" | tee -a "$LOG_FILE"
    fi
  else
    echo "FAIL: $pkg - $out" | tee -a "$LOG_FILE"
    failed=$((failed + 1))
  fi
done

echo "" | tee -a "$LOG_FILE"
echo "Removed: $removed | Failed: $failed" | tee -a "$LOG_FILE"
echo "Removed packages saved to: $REMOVED_FILE" | tee -a "$LOG_FILE"

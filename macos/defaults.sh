#!/usr/bin/env bash
# Idempotent macOS defaults. Run with --apply to make changes, otherwise DRY-RUN.
set -euo pipefail

APPLY=0
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    --dry-run) APPLY=0 ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

run() {
  if [[ $APPLY -eq 1 ]]; then
    eval "$1"
  else
    echo "DRY: $1"
  fi
}

mac_user_dir="$HOME"

# Keyboard / typing
run "defaults write -g KeyRepeat -int 1"                      # fast repeat
run "defaults write -g InitialKeyRepeat -int 15"              # delay until repeat
run "defaults write -g ApplePressAndHoldEnabled -bool false"  # enable key repeat over press-and-hold

# Trackpad
run "defaults write com.apple.AppleMultitouchTrackpad Clicking -int 1"
run "defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1"
run "defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1"   # tap to click

# Finder
run "defaults write NSGlobalDomain AppleShowAllExtensions -bool true"
run "defaults write com.apple.finder ShowPathbar -bool true"
run "defaults write com.apple.finder ShowStatusBar -bool true"
run "defaults write com.apple.finder FXDefaultSearchScope -string SCcf"  # search current folder by default
run "defaults write com.apple.finder FXPreferredViewStyle -string Nlsv"   # list view
run "defaults write com.apple.finder NewWindowTarget -string PfLo"
run "defaults write com.apple.finder NewWindowTargetPath -string file://$mac_user_dir/"
run "defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true"
run "defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true"

# Dock
run "defaults write com.apple.dock autohide -bool true"
run "defaults write com.apple.dock show-recents -bool false"
run "defaults write com.apple.dock mru-spaces -bool false"
run "defaults write com.apple.dock tilesize -int 48"

# Screenshots
run "mkdir -p \"$HOME/Screenshots\""
run "defaults write com.apple.screencapture location -string \"$HOME/Screenshots\""
run "defaults write com.apple.screencapture type -string png"
# run "defaults write com.apple.screencapture disable-shadow -bool true"  # uncomment if desired

# Privacy/telemetry
run "defaults write com.apple.applicationaccess NewUserNotificationCenterEnabled -bool false || true"
run "defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true"   # keep security updates checked

# Menu bar clock: show date and seconds (Sonoma+ uses plist)
run "/usr/libexec/PlistBuddy -c \"Set :MenuBarClock.ShowSeconds true\" \"$HOME/Library/Preferences/com.apple.menuextra.clock.plist\" 2>/dev/null || true"

# Apply: restart affected services
if [[ $APPLY -eq 1 ]]; then
  killall Dock 2>/dev/null || true
  killall Finder 2>/dev/null || true
  killall SystemUIServer 2>/dev/null || true
  echo "Applied macOS defaults."
else
  echo "macOS defaults DRY-RUN complete. Use --apply to make changes."
fi

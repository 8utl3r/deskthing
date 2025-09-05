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
run "defaults write -g ApplePressAndHoldEnabled -bool false"  # key repeat over press-and-hold
run "defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false"
run "defaults write -g NSAutomaticCapitalizationEnabled -bool false"
run "defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false"
run "defaults write -g NSAutomaticDashSubstitutionEnabled -bool false"
run "defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false"
run "defaults write -g AppleKeyboardUIMode -int 3"            # full keyboard access

# Trackpad
run "defaults write com.apple.AppleMultitouchTrackpad Clicking -int 1"
run "defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1"
run "defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1"   # tap to click

# Finder
run "defaults write NSGlobalDomain AppleShowAllExtensions -bool true"
run "defaults write com.apple.finder AppleShowAllFiles -bool true"
run "defaults write com.apple.finder _FXSortFoldersFirst -bool true"
run "defaults write com.apple.finder ShowPathbar -bool true"
run "defaults write com.apple.finder ShowStatusBar -bool true"
run "defaults write com.apple.finder FXDefaultSearchScope -string SCcf"  # search current folder by default
run "defaults write com.apple.finder FXPreferredViewStyle -string Nlsv"   # list view
run "defaults write com.apple.finder NewWindowTarget -string PfLo"
run "defaults write com.apple.finder NewWindowTargetPath -string file://$mac_user_dir/"
run "defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true"
run "defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true"
run "defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false" # no extension change warning
run "defaults write com.apple.finder WarnOnEmptyTrash -bool false"              # no empty trash warning
run "defaults write com.apple.finder QuitMenuItem -bool true"                   # allow Finder to Quit
run "defaults write com.apple.finder QLEnableTextSelection -bool true"         # text selection in Quick Look
run "defaults write com.apple.finder _FXShowPosixPathInTitle -bool true"       # show full POSIX path in title
run "defaults write com.apple.finder DisableAllAnimations -bool true"          # faster Finder
run "defaults write com.apple.finder FXInfoPanesExpanded -dict General -bool true OpenWith -bool true Privileges -bool true"
run "chflags nohidden \"$HOME/Library\""                                      # reveal ~/Library

# Dock
run "defaults write com.apple.dock autohide -bool true"
run "defaults write com.apple.dock show-recents -bool false"
run "defaults write com.apple.dock mru-spaces -bool false"
run "defaults write com.apple.dock tilesize -int 48"
# Optional: clear pinned apps to start clean (commented by default)
# run "defaults delete com.apple.dock persistent-apps 2>/dev/null || true"
run "defaults write com.apple.dock wvous-tl-corner -int 0"
run "defaults write com.apple.dock wvous-tr-corner -int 0"
run "defaults write com.apple.dock wvous-bl-corner -int 0"
run "defaults write com.apple.dock wvous-br-corner -int 0"
run "defaults write com.apple.dock wvous-tl-modifier -int 0"
run "defaults write com.apple.dock wvous-tr-modifier -int 0"
run "defaults write com.apple.dock wvous-bl-modifier -int 0"
run "defaults write com.apple.dock wvous-br-modifier -int 0"
run "defaults write com.apple.dock autohide-delay -float 0"                     # no dock delay
run "defaults write com.apple.dock autohide-time-modifier -float 0.12"         # faster dock animation
run "defaults write com.apple.dock mineffect -string scale"                    # minimize effect
run "defaults write com.apple.dock showhidden -bool true"                      # translucent icons for hidden apps

# Screenshots
run "mkdir -p \"$HOME/Screenshots\""
run "defaults write com.apple.screencapture location -string \"$HOME/Screenshots\""
run "defaults write com.apple.screencapture type -string png"
run "defaults write com.apple.screencapture disable-shadow -bool true"

# Save/print panels and document behavior
run "defaults write -g NSNavPanelExpandedStateForSaveMode -bool true"
run "defaults write -g NSNavPanelExpandedStateForSaveMode2 -bool true"
run "defaults write -g PMPrintingExpandedStateForPrint -bool true"
run "defaults write -g PMPrintingExpandedStateForPrint2 -bool true"
run "defaults write -g NSDocumentSaveNewDocumentsToCloud -bool false"   # default to local, not iCloud

# Battery percentage (new and legacy locations)
run "defaults write com.apple.controlcenter BatteryShowPercentage -bool true"
run "defaults write com.apple.menuextra.battery ShowPercent -string YES"

# Natural scroll (explicitly true)
run "defaults write -g com.apple.swipescrolldirection -bool true"
run "defaults write -g AppleShowScrollBars -string WhenScrolling"              # show scroll bars when scrolling

# Prevent Photos from auto-opening on device plug-in
run "defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true"

# Networking / AirDrop
run "defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true"   # AirDrop on all interfaces

# Prevent sleep (optional - uncomment to enable)
# run "sudo pmset -a sleep 0 displaysleep 0" # Prevent all sleep
# run "sudo pmset -a displaysleep 0" # Prevent display sleep only

# Privacy/telemetry (user-level; avoids sudo)
run "defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false"     # personalized ads off
run "defaults -currentHost write com.apple.AdLib allowApplePersonalizedAdvertising -bool false"
run "defaults write com.apple.SubmitDiagInfo AutoSubmit -bool false"                   # analytics off (user)
run "defaults write com.apple.applicationaccess AllowDiagnosticSubmission -bool false" # no diag submission
run "defaults write com.apple.CrashReporter DialogType -string none"                   # no crash dialog
run "defaults write com.apple.assistant.support \"Assistant Enabled\" -bool false"        # Siri disabled UI
run "defaults write com.apple.Siri StatusMenuVisible -bool false"
run "defaults write com.apple.Siri UserHasDeclinedEnable -bool true"

# Menu bar clock: show seconds (Sonoma+ plist may be rewritten by UI)
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

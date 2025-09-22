#!/bin/bash

# Karabiner Profile Switcher for Alfred
# Usage: ./karabiner_profile_switcher.sh <profile_name>

PROFILE_NAME="$1"
KARABINER_CONFIG="$HOME/.config/karabiner/karabiner.json"

if [ -z "$PROFILE_NAME" ]; then
    echo "Usage: $0 <profile_name>"
    echo "Available profiles:"
    jq -r '.profiles[].name' "$KARABINER_CONFIG" 2>/dev/null || echo "Error reading profiles"
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Install with: brew install jq"
    exit 1
fi

# Check if profile exists
if ! jq -e --arg name "$PROFILE_NAME" '.profiles[] | select(.name == $name)' "$KARABINER_CONFIG" > /dev/null; then
    echo "Error: Profile '$PROFILE_NAME' not found"
    echo "Available profiles:"
    jq -r '.profiles[].name' "$KARABINER_CONFIG"
    exit 1
fi

# Create backup
cp "$KARABINER_CONFIG" "$KARABINER_CONFIG.backup.$(date +%s)"

# Update the selected profile
jq --arg name "$PROFILE_NAME" '
    .profiles[] |= if .name == $name then .selected = true else .selected = false end
' "$KARABINER_CONFIG" > "$KARABINER_CONFIG.tmp" && mv "$KARABINER_CONFIG.tmp" "$KARABINER_CONFIG"

if [ $? -eq 0 ]; then
    echo "Switched to profile: $PROFILE_NAME"
    # Reload Karabiner configuration
    /Applications/Karabiner-Elements.app/Contents/Library/bin/karabiner_cli --reload-configuration
else
    echo "Error: Failed to switch profile"
    exit 1
fi

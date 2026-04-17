#!/usr/bin/env bash
# Install minidsp-rs CLI and daemon for DDRC-24 control.
# Requires DDRC-24 connected via USB.
# Usage: ./scripts/install-minidsp.sh [--no-launchd]

set -euo pipefail

VERSION="v0.1.12"
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
  # No native ARM build; use x86_64 (runs under Rosetta 2)
  TAR="minidsp.x86_64-apple-darwin.tar.gz"
else
  TAR="minidsp.x86_64-apple-darwin.tar.gz"
fi
URL="https://github.com/mrene/minidsp-rs/releases/download/${VERSION}/${TAR}"
INSTALL_DIR="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.config/minidsp"
CONFIG_FILE="${CONFIG_DIR}/config.toml"
DOTFILES_MINIDSP="${HOME}/dotfiles/minidsp/config.toml"

SKIP_LAUNCHD=0
for arg in "$@"; do
  case "$arg" in
    --no-launchd) SKIP_LAUNCHD=1 ;;
  esac
done

mkdir -p "$INSTALL_DIR" "$CONFIG_DIR"

echo "Downloading minidsp-rs ${VERSION}..."
cd "$(mktemp -d)"
curl -sSL -o minidsp.tar.gz "$URL"
tar -xzf minidsp.tar.gz

echo "Installing to ${INSTALL_DIR}..."
cp -f minidsp minidspd "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/minidsp" "$INSTALL_DIR/minidspd"

# Config: use dotfiles version if present, else create default
if [[ -f "$DOTFILES_MINIDSP" ]]; then
  echo "Linking config from dotfiles..."
  ln -sf "$DOTFILES_MINIDSP" "$CONFIG_FILE"
else
  echo "Creating default config..."
  cat > "$CONFIG_FILE" << 'EOF'
# MiniDSP DDRC-24 minidsp-rs daemon config
[http_server]
bind_address = "127.0.0.1:5380"
[[tcp_server]]
bind_address = "127.0.0.1:5333"
EOF
fi

echo "Installed:"
"$INSTALL_DIR/minidsp" --version 2>/dev/null || "$INSTALL_DIR/minidsp" -V 2>/dev/null || true
"$INSTALL_DIR/minidspd" -V 2>/dev/null || true

# LaunchAgent to run minidspd at login
if [[ $SKIP_LAUNCHD -eq 0 ]]; then
  PLIST="${HOME}/Library/LaunchAgents/com.minidsp.daemon.plist"
  mkdir -p "$(dirname "$PLIST")"
  cat > "$PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.minidsp.daemon</string>
  <key>ProgramArguments</key>
  <array>
    <string>${INSTALL_DIR}/minidspd</string>
    <string>-c</string>
    <string>${CONFIG_FILE}</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>${HOME}/Library/Logs/minidspd.log</string>
  <key>StandardErrorPath</key>
  <string>${HOME}/Library/Logs/minidspd.err</string>
</dict>
</plist>
EOF
  echo "LaunchAgent created: $PLIST"
  echo "Loading daemon..."
  launchctl unload "$PLIST" 2>/dev/null || true
  launchctl load "$PLIST"
  echo "minidspd started. Check: launchctl list | grep minidsp"
else
  echo "Skipping LaunchAgent. Run manually: minidspd -c $CONFIG_FILE"
fi

echo ""
echo "Done. Ensure DDRC-24 is connected via USB."
echo "Test: minidsp (no args) or curl http://127.0.0.1:5380/devices"

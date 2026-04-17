#!/bin/bash
# Setup Factorio n8n Controller as macOS LaunchAgent service

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_NAME="com.pete.factorio-n8n-controller.plist"
PLIST_SOURCE="$SCRIPT_DIR/$PLIST_NAME"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME"
LOGS_DIR="$SCRIPT_DIR/logs"

echo "🔧 Setting up Factorio n8n Controller as macOS service"
echo "========================================================"
echo ""

# Check if plist exists
if [ ! -f "$PLIST_SOURCE" ]; then
    echo "❌ Error: $PLIST_SOURCE not found"
    exit 1
fi

# Create logs directory
echo "📁 Creating logs directory..."
mkdir -p "$LOGS_DIR"
echo "✅ Created: $LOGS_DIR"

# Check if service is already loaded
if launchctl list | grep -q "com.pete.factorio-n8n-controller"; then
    echo "⚠️  Service is already loaded. Unloading first..."
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
    echo "✅ Unloaded existing service"
fi

# Copy plist to LaunchAgents
echo "📋 Installing service..."
cp "$PLIST_SOURCE" "$PLIST_DEST"
echo "✅ Installed: $PLIST_DEST"

# Load the service
echo "🚀 Loading service..."
launchctl load "$PLIST_DEST"
echo "✅ Service loaded"

# Start the service
echo "▶️  Starting service..."
launchctl start com.pete.factorio-n8n-controller
echo "✅ Service started"

echo ""
echo "✅ Setup complete!"
echo ""
echo "Service Status:"
launchctl list | grep "com.pete.factorio-n8n-controller" || echo "   (checking status...)"
echo ""
echo "Logs:"
echo "   - Output: $LOGS_DIR/factorio-controller.log"
echo "   - Errors: $LOGS_DIR/factorio-controller.error.log"
echo ""
echo "Commands:"
echo "   - Check status: launchctl list | grep factorio"
echo "   - View logs: tail -f $LOGS_DIR/factorio-controller.log"
echo "   - Stop: launchctl stop com.pete.factorio-n8n-controller"
echo "   - Start: launchctl start com.pete.factorio-n8n-controller"
echo "   - Unload: launchctl unload $PLIST_DEST"
echo ""

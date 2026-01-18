#!/bin/bash
# Configure Ollama memory limit
# Usage: ./configure_memory_limit.sh [memory_in_gb]
# Default: 8GB

set -e

MEMORY_GB=${1:-8}
MEMORY_BYTES=$((MEMORY_GB * 1024 * 1024 * 1024))
PLIST="$HOME/Library/LaunchAgents/homebrew.mxcl.ollama.plist"

echo "🔧 Configuring Ollama memory limit to ${MEMORY_GB}GB..."

# Ensure Ollama is running so plist exists
if ! brew services list | grep -q "ollama.*started"; then
    echo "   Starting Ollama to create plist..."
    brew services start ollama >/dev/null 2>&1
    sleep 3
fi

# Wait for plist to exist
for i in {1..10}; do
    if [ -f "$PLIST" ]; then
        break
    fi
    sleep 1
done

if [ ! -f "$PLIST" ]; then
    echo "❌ Plist not found at $PLIST after waiting"
    echo "   Make sure Ollama service is running: brew services start ollama"
    exit 1
fi

# Use Python to reliably edit the plist XML
python3 << PYEOF
import plistlib
import os

plist_path = "$PLIST"
memory_bytes = $MEMORY_BYTES

if not os.path.exists(plist_path):
    print(f"❌ Plist not found at {plist_path}")
    exit(1)

with open(plist_path, 'rb') as f:
    plist = plistlib.load(f)

if 'SoftResourceLimits' not in plist:
    plist['SoftResourceLimits'] = {}

plist['SoftResourceLimits']['memory'] = memory_bytes

with open(plist_path, 'wb') as f:
    plistlib.dump(plist, f)

print(f"✅ Memory limit set to ${MEMORY_GB}GB ({memory_bytes:,} bytes)")
PYEOF

echo ""
echo "🔄 Restarting Ollama to apply changes..."
brew services restart ollama >/dev/null 2>&1
sleep 3

# Re-apply limit after restart (brew services may regenerate plist)
if [ -f "$PLIST" ]; then
    python3 << PYEOF
import plistlib
import os

plist_path = "$PLIST"
memory_bytes = $MEMORY_BYTES

with open(plist_path, 'rb') as f:
    plist = plistlib.load(f)

if 'SoftResourceLimits' not in plist:
    plist['SoftResourceLimits'] = {}

plist['SoftResourceLimits']['memory'] = memory_bytes

with open(plist_path, 'wb') as f:
    plistlib.dump(plist, f)
PYEOF
fi

sleep 2
echo ""
echo "✅ Configuration complete!"
echo ""
echo "Current settings:"
plutil -p "$PLIST" | grep -A 2 SoftResourceLimits || echo "   (No memory limit set)"

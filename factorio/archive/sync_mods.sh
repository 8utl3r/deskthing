#!/bin/bash
# Script to sync mods from Factorio client on Mac to TrueNAS server

SERVER_USER="truenas_admin"
SERVER_HOST="192.168.0.158"
SERVER_MODS_DIR="/mnt/boot-pool/apps/factorio/mods"

echo "Factorio Mod Sync Script"
echo "======================"
echo ""
echo "This script syncs mods from your Mac Factorio client to the server."
echo ""

# Try to find Factorio mods directory (check multiple locations)
FACTORIO_MODS_DIR=""

# Check common locations
if [ -d "$HOME/.factorio/mods" ]; then
    FACTORIO_MODS_DIR="$HOME/.factorio/mods"
elif [ -d "$HOME/Library/Application Support/factorio/mods" ]; then
    FACTORIO_MODS_DIR="$HOME/Library/Application Support/factorio/mods"
elif [ -d "$HOME/Library/Application Support/Steam/steamapps/common/Factorio/mods" ]; then
    FACTORIO_MODS_DIR="$HOME/Library/Application Support/Steam/steamapps/common/Factorio/mods"
elif [ -d "$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio/mods" ]; then
    FACTORIO_MODS_DIR="$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio/mods"
fi

# If still not found, ask user
if [ -z "$FACTORIO_MODS_DIR" ]; then
    echo "⚠️  Could not automatically find Factorio mods directory."
    echo ""
    echo "Common locations:"
    echo "  - ~/.factorio/mods"
    echo "  - ~/Library/Application Support/factorio/mods"
    echo "  - ~/Library/Application Support/Steam/steamapps/common/Factorio/mods"
    echo ""
    read -p "Enter the full path to your Factorio mods directory: " FACTORIO_MODS_DIR
    
    if [ ! -d "$FACTORIO_MODS_DIR" ]; then
        echo "❌ Error: Directory not found: $FACTORIO_MODS_DIR"
        exit 1
    fi
else
    echo "✅ Found Factorio mods directory: $FACTORIO_MODS_DIR"
fi

# List available mods
echo "Available mods in local Factorio client:"
echo "----------------------------------------"
ls -1 "$FACTORIO_MODS_DIR"/*.zip 2>/dev/null | while read mod; do
    basename "$mod"
done

echo ""
read -p "Sync all mods to server? (y/n): " sync_all

if [ "$sync_all" != "y" ]; then
    echo ""
    echo "Enter mod name to sync (or 'all' for all mods):"
    read mod_name
    
    if [ "$mod_name" == "all" ]; then
        MODS_TO_SYNC="$FACTORIO_MODS_DIR/*.zip"
    else
        MODS_TO_SYNC="$FACTORIO_MODS_DIR/${mod_name}_*.zip"
    fi
else
    MODS_TO_SYNC="$FACTORIO_MODS_DIR/*.zip"
fi

# Sync mods
echo ""
echo "Syncing mods to server..."
echo ""

for mod in $MODS_TO_SYNC; do
    if [ -f "$mod" ]; then
        mod_name=$(basename "$mod")
        echo "Syncing: $mod_name"
        scp "$mod" "${SERVER_USER}@${SERVER_HOST}:${SERVER_MODS_DIR}/" && \
            echo "  ✅ $mod_name synced" || \
            echo "  ❌ Failed to sync $mod_name"
    fi
done

echo ""
read -p "Restart Factorio server to load new mods? (y/n): " restart

if [ "$restart" == "y" ]; then
    echo ""
    echo "Restarting Factorio server..."
    ssh "${SERVER_USER}@${SERVER_HOST}" "cd /mnt/boot-pool/apps/factorio && sudo docker compose restart"
    echo ""
    echo "✅ Server restarted. Check logs to verify mods loaded:"
    echo "   ssh ${SERVER_USER}@${SERVER_HOST} 'sudo docker logs factorio | grep -i mod'"
else
    echo ""
    echo "⚠️  Don't forget to restart the server to load new mods!"
fi

echo ""
echo "Done!"

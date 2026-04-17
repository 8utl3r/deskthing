#!/bin/bash
# Check if mod is enabled in mod-list.json

echo "Checking if FV Embodied Agent mod is enabled..."
echo ""

echo "Run this on TrueNAS:"
echo ""
echo "cat /mnt/boot-pool/apps/factorio/mods/mod-list.json 2>/dev/null | grep -A 2 -B 2 embodied || echo 'No mod-list.json found'"
echo ""
echo "If the mod shows 'enabled: false', you need to enable it."
echo "The mod-list.json should have:"
echo '  {"name": "fv_embodied_agent", "enabled": true}'

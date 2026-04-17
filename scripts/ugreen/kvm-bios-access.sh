#!/usr/bin/env bash
# Prepare NAS for KVM BIOS access
# Disables USB autosuspend so KVM stays powered

set -euo pipefail

NAS_IP="192.168.0.158"
NAS_USER="pete"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Preparing NAS for KVM BIOS Access                 ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}Step 1: Disabling USB autosuspend (keeps KVM powered)...${NC}"
ssh "$NAS_USER@$NAS_IP" "echo -1 | sudo tee /sys/module/usbcore/parameters/autosuspend" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ USB autosuspend disabled${NC}\n"
    
    # Verify
    current_setting=$(ssh "$NAS_USER@$NAS_IP" "cat /sys/module/usbcore/parameters/autosuspend" 2>/dev/null)
    echo "Current setting: $current_setting (-1 = disabled)"
    echo ""
    
    echo -e "${CYAN}Step 2: Ready to reboot and access BIOS${NC}\n"
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Watch your KVM screen"
    echo "  2. Reboot NAS: ssh $NAS_USER@$NAS_IP 'sudo reboot'"
    echo "  3. When Ugreen logo appears, press F2 repeatedly"
    echo "  4. BIOS should appear on KVM screen"
    echo ""
    echo -e "${CYAN}Note:${NC} USB autosuspend is disabled temporarily."
    echo "      Set 'USB Power: Always On' in BIOS for permanent solution."
    echo ""
else
    echo -e "${RED}Failed to disable USB autosuspend${NC}"
    exit 1
fi

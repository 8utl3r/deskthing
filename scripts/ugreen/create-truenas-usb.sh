#!/usr/bin/env bash
# Create bootable TrueNAS Scale USB installer
# WARNING: This will ERASE all data on the USB drive!

set -euo pipefail

ISO_PATH="$HOME/dotfiles/downloads/TrueNAS-SCALE-25.04.2.4.iso"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║     🔥  TrueNAS Scale USB Creator  🔥                  ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

# Check if ISO exists
if [ ! -f "$ISO_PATH" ]; then
    echo -e "${RED}ERROR: ISO not found at:${NC}"
    echo "  $ISO_PATH"
    exit 1
fi

echo -e "${YELLOW}⚠️  WARNING: This will ERASE all data on the USB drive!${NC}\n"
echo "Listing available disks..."
echo ""

# List disks
diskutil list

echo ""
echo -e "${CYAN}Please identify your USB drive from the list above.${NC}"
echo -e "${CYAN}Look for the disk labeled 'pete's work' or check the size.${NC}\n"

read -p "Enter the disk identifier (e.g., disk2, disk3): " DISK_ID

if [ -z "$DISK_ID" ]; then
    echo -e "${RED}Error: No disk specified${NC}"
    exit 1
fi

# Verify it's not a system disk
if [[ "$DISK_ID" == "disk0" ]] || [[ "$DISK_ID" == "disk1" ]]; then
    echo -e "${RED}ERROR: That looks like a system disk! Aborting for safety.${NC}"
    exit 1
fi

# Get disk info
DISK_INFO=$(diskutil info "$DISK_ID" 2>/dev/null || echo "")
if [ -z "$DISK_INFO" ]; then
    echo -e "${RED}ERROR: Disk $DISK_ID not found${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Disk Information:${NC}"
echo "$DISK_INFO" | grep -E "Device Node|Device / Media Name|Total Size|File System"
echo ""

read -p "Is this the correct USB drive? (yes/no): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo -e "${CYAN}Unmounting disk...${NC}"
diskutil unmountDisk "$DISK_ID" || true

echo ""
echo -e "${CYAN}Creating bootable USB...${NC}"
echo -e "${YELLOW}This will take several minutes. Please wait...${NC}\n"

# Use dd to write ISO
sudo dd if="$ISO_PATH" of="/dev/r${DISK_ID}" bs=1m status=progress

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}${BOLD}✅ USB created successfully!${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Eject the USB: diskutil eject $DISK_ID"
    echo "  2. Insert USB into NAS"
    echo "  3. Configure BIOS (disable watchdog, set boot order)"
    echo "  4. Boot from USB and install TrueNAS"
else
    echo -e "${RED}ERROR: Failed to create USB${NC}"
    exit 1
fi

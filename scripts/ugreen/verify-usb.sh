#!/usr/bin/env bash
# Verify TrueNAS USB is ready and safe to remove

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        TrueNAS USB Verification                        ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}\n"

# Find USB drives
USB_DRIVES=$(diskutil list | grep -E "external|physical" | grep -v "internal" | awk '{print $NF}' | grep "^disk")

if [ -z "$USB_DRIVES" ]; then
    echo -e "${YELLOW}No USB drives detected.${NC}"
    echo ""
    echo "Please insert the USB drive and run this script again."
    exit 0
fi

for USB in $USB_DRIVES; do
    echo -e "${CYAN}Checking ${USB}...${NC}"
    
    # Get disk info
    DISK_INFO=$(diskutil info "$USB" 2>/dev/null)
    
    if [ -z "$DISK_INFO" ]; then
        continue
    fi
    
    # Check if it's a bootable ISO
    FILE_SYSTEM=$(echo "$DISK_INFO" | grep "File System Personality" | awk '{print $4}')
    VOLUME_NAME=$(echo "$DISK_INFO" | grep "Volume Name" | awk -F': ' '{print $2}')
    MOUNT_POINT=$(echo "$DISK_INFO" | grep "Mount Point" | awk -F': ' '{print $2}')
    
    echo "  Device: $USB"
    echo "  Volume: $VOLUME_NAME"
    echo "  File System: $FILE_SYSTEM"
    echo "  Mount Point: $MOUNT_POINT"
    
    # Check partition table
    PARTITIONS=$(diskutil list "$USB" | grep -E "^.*[0-9]+:" | head -3)
    
    if echo "$PARTITIONS" | grep -q "EFI\|FAT32\|ISO"; then
        echo -e "  ${GREEN}✅ Appears to be bootable ISO${NC}"
        
        # Check if it's mounted
        if [ -n "$MOUNT_POINT" ] && [ "$MOUNT_POINT" != "Not applicable (no file system)" ]; then
            echo -e "  ${YELLOW}⚠️  USB is mounted${NC}"
            echo "  Unmount before removing: diskutil unmountDisk $USB"
        else
            echo -e "  ${GREEN}✅ USB is unmounted - safe to remove${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚠️  Doesn't appear to be bootable ISO yet${NC}"
        echo "  May need to write TrueNAS ISO to this drive"
    fi
    
    echo ""
done

echo -e "${CYAN}Summary:${NC}"
echo "  • If USB shows as bootable ISO and is unmounted → Safe to remove"
echo "  • If USB is mounted → Unmount first: diskutil unmountDisk /dev/diskX"
echo "  • If USB doesn't show bootable partitions → Need to write ISO first"
echo ""

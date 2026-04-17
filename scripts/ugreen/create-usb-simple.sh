#!/usr/bin/env bash
# Simple script to create TrueNAS bootable USB
# USB Drive: /dev/disk4 (Pete's Work)
# Enhanced with fancy progress tracking! 🎨

set -euo pipefail

DISK_ID="disk4"
ISO_PATH="$HOME/dotfiles/downloads/TrueNAS-SCALE-25.04.2.4.iso"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Unicode blocks
FULL_BLOCK='█'
EMPTY_BLOCK='░'
SPINNER=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

spinner_idx=0
spinner() {
    spinner_idx=$(( (spinner_idx + 1) % ${#SPINNER[@]} ))
    echo -ne "\r${CYAN}${SPINNER[$spinner_idx]}${NC}"
}

# Progress bar function
draw_progress() {
    local current=$1
    local total=$2
    local width=40
    local percent=$((current * 100 / total))
    [ "$percent" -gt 100 ] && percent=100
    local filled=$((current * width / total))
    [ "$filled" -gt "$width" ] && filled=$width
    [ "$filled" -lt 0 ] && filled=0
    local empty=$((width - filled))
    
    local color="${YELLOW}"
    [ "$percent" -ge 100 ] && color="${GREEN}"
    [ "$percent" -ge 75 ] && color="${CYAN}"
    [ "$percent" -ge 50 ] && color="${BLUE}"
    
    printf "${color}"
    printf "%*s" "$filled" | tr ' ' "${FULL_BLOCK}"
    printf "%*s" "$empty" | tr ' ' "${EMPTY_BLOCK}"
    printf "${NC} %3d%%" "$percent"
}

format_size() {
    local bytes=$1
    if [ "$bytes" -ge 1073741824 ]; then
        printf "%.2f GB" $(awk "BEGIN {printf \"%.2f\", $bytes/1073741824}")
    elif [ "$bytes" -ge 1048576 ]; then
        printf "%.2f MB" $(awk "BEGIN {printf \"%.2f\", $bytes/1048576}")
    else
        printf "%d bytes" "$bytes"
    fi
}

clear
echo -e "${CYAN}${BOLD}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║        🔥  TrueNAS Scale USB Creator  🔥                       ║
║                  With Fancy Progress! 🎨                       ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

# Verify ISO exists
if [ ! -f "$ISO_PATH" ]; then
    echo -e "${RED}ERROR: ISO not found!${NC}"
    echo "Expected: $ISO_PATH"
    exit 1
fi

ISO_SIZE=$(stat -f%z "$ISO_PATH" 2>/dev/null || echo "0")
ISO_SIZE_GB=$(awk "BEGIN {printf \"%.2f\", $ISO_SIZE/1073741824}")

echo -e "${BOLD}${CYAN}Configuration:${NC}"
echo -e "  ${YELLOW}USB Drive:${NC} /dev/$DISK_ID (Pete's Work - 124 GB)"
echo -e "  ${YELLOW}ISO File:${NC} $ISO_PATH"
echo -e "  ${YELLOW}ISO Size:${NC} $ISO_SIZE_GB GB"
echo ""
echo -e "${RED}${BOLD}⚠️  WARNING: This will ERASE all data on the USB drive!${NC}\n"

read -p "Continue? (type 'yes' to proceed): " CONFIRM

if [[ ! "$CONFIRM" == "yes" ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo -e "${CYAN}${BOLD}Step 1:${NC} Unmounting USB drive..."
diskutil unmountDisk "/dev/$DISK_ID" 2>/dev/null || true
sleep 2
echo -e "${GREEN}✅ Unmounted${NC}\n"

echo -e "${CYAN}${BOLD}Step 2:${NC} Writing TrueNAS ISO to USB..."
echo -e "${YELLOW}This will take 5-10 minutes. Progress will be shown below...${NC}\n"

# Create a temporary file to track progress
PROGRESS_FILE=$(mktemp)
trap "rm -f $PROGRESS_FILE" EXIT

# Start dd in background and monitor progress
(
    sudo dd if="$ISO_PATH" of="/dev/r${DISK_ID}" bs=1m 2>&1 | \
    while IFS= read -r line; do
        # Extract bytes written from dd output
        if [[ "$line" =~ ([0-9]+)\+([0-9]+)\ records ]]; then
            bytes_written=$((${BASH_REMATCH[1]} * 1048576 + ${BASH_REMATCH[2]}))
            echo "$bytes_written" > "$PROGRESS_FILE"
        elif [[ "$line" =~ ([0-9]+)\ bytes ]]; then
            bytes_written=${BASH_REMATCH[1]}
            echo "$bytes_written" > "$PROGRESS_FILE"
        fi
    done
) &
DD_PID=$!

# Monitor progress
start_time=$(date +%s)
last_bytes=0
while kill -0 $DD_PID 2>/dev/null; do
    if [ -f "$PROGRESS_FILE" ]; then
        current_bytes=$(cat "$PROGRESS_FILE" 2>/dev/null | tr -d '[:space:]' || echo "0")
    else
        current_bytes=0
    fi
    
    # Ensure current_bytes is a valid integer (default to 0 if not)
    if ! [[ "$current_bytes" =~ ^[0-9]+$ ]]; then
        current_bytes=0
    fi
    
    # Calculate progress
    if [ "$current_bytes" -gt 0 ]; then
        progress_bar=$(draw_progress "$current_bytes" "$ISO_SIZE")
        current_size=$(format_size "$current_bytes")
        total_size=$(format_size "$ISO_SIZE")
        
        # Calculate speed
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))
        if [ "$elapsed" -gt 0 ] && [ "$current_bytes" -gt "$last_bytes" ]; then
            bytes_per_sec=$(( (current_bytes - last_bytes) / elapsed ))
            speed=$(format_size "$bytes_per_sec")
            speed_str="${CYAN}@ $speed/s${NC}"
        else
            speed_str=""
        fi
        
        # Calculate ETA
        if [ "$current_bytes" -gt 0 ] && [ "$elapsed" -gt 0 ]; then
            bytes_per_sec=$((current_bytes / elapsed))
            if [ "$bytes_per_sec" -gt 0 ]; then
                remaining_bytes=$((ISO_SIZE - current_bytes))
                eta_seconds=$((remaining_bytes / bytes_per_sec))
                eta_min=$((eta_seconds / 60))
                eta_sec=$((eta_seconds % 60))
                eta_str="${YELLOW}ETA: ${eta_min}m ${eta_sec}s${NC}"
            else
                eta_str=""
            fi
        else
            eta_str=""
        fi
        
        # Display progress
        printf "\r${CYAN}Writing:${NC} $progress_bar  $current_size / $total_size  $speed_str  $eta_str"
        last_bytes=$current_bytes
        start_time=$current_time
    else
        spinner
    fi
    
    sleep 1
done

wait $DD_PID
DD_EXIT=$?

echo "" # New line after progress

if [ $DD_EXIT -eq 0 ]; then
    echo ""
    echo -e "${GREEN}${BOLD}✅ USB created successfully!${NC}\n"
    
    echo -e "${CYAN}${BOLD}Step 3:${NC} Ejecting USB..."
    diskutil eject "/dev/$DISK_ID"
    
    echo ""
    echo -e "${GREEN}${BOLD}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║           ✅  USB READY FOR INSTALLATION  ✅                   ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
    
    echo -e "${CYAN}${BOLD}Next steps:${NC}"
    echo "  1. ✅ USB created and ejected"
    echo "  2. ⏭️  Insert USB into NAS (use USB 2.0 port if available)"
    echo "  3. ⏭️  Configure BIOS (disable watchdog, set boot order)"
    echo "  4. ⏭️  Boot from USB and install TrueNAS Scale"
    echo ""
else
    echo -e "${RED}${BOLD}ERROR: Failed to create USB${NC}"
    echo "Exit code: $DD_EXIT"
    exit 1
fi

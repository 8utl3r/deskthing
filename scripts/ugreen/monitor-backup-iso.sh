#!/usr/bin/env bash
# Fancy progress monitor for UGOS backup and TrueNAS ISO download
# Entertaining graphics included! 🎨

set -euo pipefail

NAS_IP="192.168.0.158"
NAS_USER="pete"
BACKUP_PATH="/volume1/ugos_backup.img"
ISO_PATH="$HOME/dotfiles/downloads/TrueNAS-SCALE-25.04.2.4.iso"
EXPECTED_BACKUP_SIZE=30720000000  # ~30GB in bytes
EXPECTED_ISO_SIZE=2300000000      # ~2.15GB in bytes

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Unicode blocks
FULL_BLOCK='█'
EMPTY_BLOCK='░'
CHECK='✓'
CROSS='✗'
SPINNER=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

spinner_idx=0

spinner() {
    spinner_idx=$(( (spinner_idx + 1) % ${#SPINNER[@]} ))
    echo -ne "${SPINNER[$spinner_idx]}"
}

format_size() {
    local bytes=$1
    if [ "$bytes" -ge 1073741824 ]; then
        printf "%.2f GB" $(echo "scale=2; $bytes/1073741824" | bc 2>/dev/null || echo "scale=2; $bytes/1073741824" | awk '{printf "%.2f", $1/1073741824}')
    elif [ "$bytes" -ge 1048576 ]; then
        printf "%.2f MB" $(echo "scale=2; $bytes/1048576" | bc 2>/dev/null || echo "scale=2; $bytes/1048576" | awk '{printf "%.2f", $1/1048576}')
    else
        printf "%d bytes" "$bytes"
    fi
}

draw_bar() {
    local current=$1
    local total=$2
    local width=50
    local percent
    
    if [ "$total" -eq 0 ]; then
        percent=0
    else
        percent=$((current * 100 / total))
    fi
    
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

get_backup_size() {
    ssh "$NAS_USER@$NAS_IP" "stat -c%s '$BACKUP_PATH' 2>/dev/null || echo '0'" 2>/dev/null || echo "0"
}

is_backup_running() {
    ssh "$NAS_USER@$NAS_IP" "ps aux | grep '[d]d if=/dev/mmcblk0' | wc -l" 2>/dev/null | grep -q "1"
}

get_iso_size() {
    [ -f "$ISO_PATH" ] && stat -f%z "$ISO_PATH" 2>/dev/null || echo "0"
}

is_iso_running() {
    pgrep -f "[c]url.*TrueNAS" > /dev/null 2>&1
}

# Clear screen and show header
clear
echo -e "${CYAN}${BOLD}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║        🚀  UGOS Backup & TrueNAS ISO Monitor  🚀              ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

backup_done=false
iso_done=false
iteration=0

while true; do
    iteration=$((iteration + 1))
    
    # Get current status
    backup_size=$(get_backup_size)
    backup_running=$(is_backup_running && echo "true" || echo "false")
    iso_size=$(get_iso_size)
    iso_running=$(is_iso_running && echo "true" || echo "false")
    
    # Determine backup status
    if [ "$backup_size" -ge "$EXPECTED_BACKUP_SIZE" ] || ([ "$backup_running" = "false" ] && [ "$backup_size" -gt 0 ]); then
        backup_status="${GREEN}${CHECK} COMPLETE${NC}"
        backup_done=true
    elif [ "$backup_running" = "true" ]; then
        spinner_char="${SPINNER[$((iteration % ${#SPINNER[@]}))]}"
        backup_status="${CYAN}${spinner_char} BACKING UP${NC}"
    else
        backup_status="${YELLOW}▶ WAITING${NC}"
    fi
    
    # Determine ISO status
    if [ "$iso_size" -ge "$EXPECTED_ISO_SIZE" ] || ([ "$iso_running" = "false" ] && [ "$iso_size" -gt 1000000 ]); then
        iso_status="${GREEN}${CHECK} COMPLETE${NC}"
        iso_done=true
    elif [ "$iso_running" = "true" ]; then
        spinner_char="${SPINNER[$((iteration % ${#SPINNER[@]}))]}"
        iso_status="${CYAN}${spinner_char} DOWNLOADING${NC}"
    else
        iso_status="${YELLOW}▶ WAITING${NC}"
    fi
    
    # Clear previous output (6 lines)
    printf "\033[6A\033[K"
    
    # Display status
    echo -e "${BOLD}${WHITE}📦 UGOS Backup${NC}          ${backup_status}"
    backup_bar=$(draw_bar "$backup_size" "$EXPECTED_BACKUP_SIZE")
    echo -e "   ${backup_bar}"
    echo -e "   ${CYAN}$(format_size $backup_size)${NC} / ${WHITE}$(format_size $EXPECTED_BACKUP_SIZE)${NC}"
    echo ""
    
    echo -e "${BOLD}${WHITE}💿 TrueNAS ISO${NC}          ${iso_status}"
    iso_bar=$(draw_bar "$iso_size" "$EXPECTED_ISO_SIZE")
    echo -e "   ${iso_bar}"
    echo -e "   ${CYAN}$(format_size $iso_size)${NC} / ${WHITE}$(format_size $EXPECTED_ISO_SIZE)${NC}"
    echo ""
    
    # Completion check
    if [ "$backup_done" = "true" ] && [ "$iso_done" = "true" ]; then
        echo ""
        echo -e "${GREEN}${BOLD}"
        cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║           🎉  ALL TASKS COMPLETE!  🎉                          ║
║                                                                  ║
║     Ready for TrueNAS installation!                             ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
        echo -e "${NC}"
        break
    fi
    
    sleep 2
done

echo -e "\n${CYAN}Next steps:${NC}"
echo -e "  1. Create bootable USB from ISO"
echo -e "  2. Configure BIOS (disable watchdog, set boot order)"
echo -e "  3. Install TrueNAS Scale on NVMe"
echo ""

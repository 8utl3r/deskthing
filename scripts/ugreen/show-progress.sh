#!/usr/bin/env bash
# Simple progress display for chat

NAS_IP="192.168.0.158"
NAS_USER="pete"
BACKUP_PATH="/volume1/ugos_backup.img"
ISO_PATH="$HOME/dotfiles/downloads/TrueNAS-SCALE-25.04.2.4.iso"
EXPECTED_BACKUP=30720000000
EXPECTED_ISO=2300000000

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

get_backup_size() {
    ssh "$NAS_USER@$NAS_IP" "stat -c%s '$BACKUP_PATH' 2>/dev/null || echo '0'" 2>/dev/null || echo "0"
}

get_iso_size() {
    [ -f "$ISO_PATH" ] && stat -f%z "$ISO_PATH" 2>/dev/null || echo "0"
}

backup_size=$(get_backup_size)
iso_size=$(get_iso_size)

backup_gb=$(echo "scale=2; $backup_size/1073741824" | bc 2>/dev/null || awk "BEGIN {printf \"%.2f\", $backup_size/1073741824}")
iso_gb=$(echo "scale=2; $iso_size/1073741824" | bc 2>/dev/null || awk "BEGIN {printf \"%.2f\", $iso_size/1073741824}")

backup_percent=$((backup_size * 100 / EXPECTED_BACKUP))
iso_percent=$((iso_size * 100 / EXPECTED_ISO))

[ "$backup_percent" -gt 100 ] && backup_percent=100
[ "$iso_percent" -gt 100 ] && iso_percent=100

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  📦 UGOS Backup Progress                                ║"
echo "║  $backup_gb GB / 30.00 GB (${backup_percent}%)"
echo "║                                                          ║"
echo "║  💿 TrueNAS ISO Download                                 ║"
echo "║  $iso_gb GB / 2.15 GB (${iso_percent}%)"
echo "╚══════════════════════════════════════════════════════════╝"

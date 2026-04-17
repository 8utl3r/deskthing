#!/bin/bash
# Step-by-step NVMe partitioning script for fast-pool creation
# Run each section separately and verify before proceeding

set -e  # Exit on error

echo "=== Step 1: Check Current Boot-Pool Usage ==="
echo "Checking boot-pool status..."
sudo zpool list boot-pool
echo ""
echo "Checking boot-pool datasets..."
sudo zfs list boot-pool
echo ""
echo "✅ Review the output above. Boot-pool should show ~5-10GB used out of ~931GB"
echo "Press Enter to continue to Step 2..."
read

echo ""
echo "=== Step 2: Check Current Partition Layout ==="
echo "Checking partition table..."
sudo fdisk -l /dev/nvme0n1
echo ""
echo "Checking block devices..."
sudo lsblk /dev/nvme0n1
echo ""
echo "✅ Review the partition layout. Note partition 2 (boot-pool) size"
echo "Press Enter to continue to Step 3..."
read

echo ""
echo "=== Step 3: Backup Partition Table ==="
echo "Creating backup of partition table..."
sudo sfdisk -d /dev/nvme0n1 > /tmp/nvme0n1.backup
echo "Backup saved to: /tmp/nvme0n1.backup"
echo ""
echo "Verifying backup..."
cat /tmp/nvme0n1.backup
echo ""
echo "✅ Backup created. Save this file somewhere safe!"
echo "Press Enter to continue to Step 4 (EXPORT BOOT-POOL - SYSTEM WILL BE READ-ONLY)..."
read

echo ""
echo "=== Step 4: Export Boot-Pool (⚠️ SYSTEM BECOMES READ-ONLY) ==="
echo "⚠️ WARNING: After this, system will be read-only!"
echo "Make sure you have console/KVM access!"
echo ""
echo "Exporting boot-pool..."
sudo zpool export boot-pool
echo ""
echo "Verifying export..."
sudo zpool list
echo ""
echo "✅ Boot-pool exported. System is now read-only."
echo "⚠️ If something goes wrong, you can re-import: sudo zpool import boot-pool"
echo "Press Enter to continue to Step 5 (RESIZE PARTITION)..."
read

echo ""
echo "=== Step 5: Resize Boot-Pool Partition ==="
echo "⚠️ CRITICAL STEP: Resizing partition 2 to 50GB"
echo ""
echo "Opening parted in interactive mode..."
echo "You'll need to run these commands manually:"
echo "  (parted) resizepart 2 50GB"
echo "  (parted) print"
echo "  (parted) quit"
echo ""
echo "Starting parted..."
sudo parted /dev/nvme0n1

echo ""
echo "=== Step 6: Create New Partition for fast-pool ==="
echo "Creating new partition for fast-pool..."
echo ""
echo "Opening parted again..."
echo "You'll need to run these commands manually:"
echo "  (parted) mkpart primary 50GB 100%"
echo "  (parted) set 3 type 6E21"
echo "  (parted) print"
echo "  (parted) quit"
echo ""
echo "Starting parted..."
sudo parted /dev/nvme0n1

echo ""
echo "=== Step 7: Verify New Partition ==="
echo "Checking partition layout..."
sudo parted /dev/nvme0n1 print
echo ""
sudo lsblk /dev/nvme0n1
echo ""
echo "✅ Should show 3 partitions:"
echo "   1: EFI boot (~512MB)"
echo "   2: boot-pool (50GB)"
echo "   3: fast-pool (~880GB)"
echo "Press Enter to continue to Step 8 (RE-IMPORT BOOT-POOL)..."
read

echo ""
echo "=== Step 8: Re-import Boot-Pool ==="
echo "Importing boot-pool (system becomes read-write again)..."
sudo zpool import boot-pool
echo ""
echo "Verifying boot-pool..."
sudo zpool status boot-pool
sudo zpool list boot-pool
echo ""
echo "✅ Boot-pool re-imported. System should be back to normal."
echo "Press Enter to continue to Step 9 (CREATE FAST-POOL)..."
read

echo ""
echo "=== Step 9: Create fast-pool ==="
echo "Creating fast-pool on new partition..."
echo ""
echo "Finding new partition..."
NEW_PARTITION=$(sudo lsblk -n -o NAME /dev/nvme0n1 | tail -1)
echo "New partition: /dev/$NEW_PARTITION"
echo ""
echo "Creating fast-pool..."
sudo zpool create fast-pool /dev/$NEW_PARTITION
echo ""
echo "Verifying fast-pool..."
sudo zpool list fast-pool
sudo zpool status fast-pool
echo ""
echo "✅ fast-pool created!"
echo "Press Enter to continue to Step 10 (CREATE DATASETS)..."
read

echo ""
echo "=== Step 10: Create Datasets ==="
echo "Creating datasets for Factorio..."
sudo zfs create fast-pool/apps
sudo zfs create fast-pool/apps/factorio
echo ""
echo "Setting permissions..."
sudo chown -R apps:apps /mnt/fast-pool/apps/factorio
sudo chmod 755 /mnt/fast-pool/apps/factorio
echo ""
echo "Verifying datasets..."
sudo zfs list fast-pool
ls -la /mnt/fast-pool/apps/factorio
echo ""
echo "✅ Datasets created and permissions set!"
echo ""
echo "=== ALL STEPS COMPLETE! ==="
echo ""
echo "Summary:"
sudo zpool list
echo ""
echo "✅ fast-pool is ready for Factorio!"
echo "Path: /mnt/fast-pool/apps/factorio"

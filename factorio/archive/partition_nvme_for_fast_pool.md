# Partition NVMe to Create fast-pool

## Overview

Shrink boot-pool partition and create fast-pool from unused NVMe space. This frees up ~800GB+ for fast-pool while keeping boot-pool safe.

## Current Situation

- **NVMe**: 931GB total
- **boot-pool**: Uses entire NVMe (but only 5.60GB actually used)
- **Goal**: Create fast-pool using ~800GB of unused space

## ⚠️ Important Warnings

- **Backup first**: Export boot-pool config before starting
- **Maintenance window**: Plan for potential downtime
- **Test first**: If possible, test on a non-critical system
- **Have recovery plan**: Keep TrueNAS installer USB ready

## Prerequisites

1. ✅ TrueNAS installer USB ready (for recovery if needed)
2. ✅ Backup of important data
3. ✅ Console/KVM access to NAS
4. ✅ Maintenance window scheduled

## Step-by-Step Process

### Step 1: Check Current Boot-Pool Usage

**Via TrueNAS Web UI:**
1. Go to **Storage** → **Pools**
2. Click on **boot-pool**
3. Note the **Used** space (should be ~5-10GB)

**Via SSH:**
```bash
ssh pete@192.168.0.158
sudo zpool list boot-pool
sudo zfs list boot-pool
```

**Expected output:**
- Total: ~931GB
- Used: ~5-10GB
- Available: ~920GB+ (unused!)

### Step 2: Check Current Partition Layout

**Via SSH:**
```bash
sudo fdisk -l /dev/nvme0n1
sudo lsblk /dev/nvme0n1
```

**You should see:**
- `nvme0n1p1`: Small (EFI boot, ~512MB)
- `nvme0n1p2`: Large (boot-pool, ~930GB)

### Step 3: Calculate Partition Sizes

**Recommended allocation:**
- **boot-pool**: 50GB (plenty of room for growth)
- **fast-pool**: 800GB (for apps)
- **Buffer**: ~80GB (safety margin)

**Total**: ~930GB (leaving ~1GB for partition overhead)

### Step 4: Export Boot-Pool (⚠️ System Becomes Read-Only)

**⚠️ WARNING**: After this step, TrueNAS will be read-only. You'll need console/KVM access.

**Via SSH:**
```bash
# Export boot-pool (makes system read-only)
sudo zpool export boot-pool

# Verify it's exported
sudo zpool list
# boot-pool should not appear
```

**What happens:**
- System continues running (read-only)
- Web UI may become unresponsive
- SSH still works (read-only)
- You can still access console

### Step 5: Resize Boot-Pool Partition

**This is the critical step.** We'll use Linux tools (`parted` or `fdisk`) to resize the partition.

**⚠️ IMPORTANT**: TrueNAS Scale is Linux-based, so we use Linux partitioning tools, not FreeBSD tools.

**Via SSH (in read-only mode):**
```bash
# Check current partition table
sudo parted /dev/nvme0n1 print
# or
sudo fdisk -l /dev/nvme0n1

# You should see something like:
# /dev/nvme0n1p1: 512MB (EFI boot)
# /dev/nvme0n1p2: ~930GB (boot-pool ZFS)

# Backup partition table first!
sudo sfdisk -d /dev/nvme0n1 > /tmp/nvme0n1.backup

# Resize partition 2 (boot-pool) to 50GB
# Using parted (interactive, safer):
sudo parted /dev/nvme0n1
# In parted:
# (parted) resizepart 2 50GB
# (parted) print
# (parted) quit

# Or using fdisk (more manual):
# 1. Delete partition 2
# 2. Recreate partition 2 with 50GB size
# 3. Keep same partition type (Linux filesystem/ZFS)
# ⚠️ This is more risky - use parted if possible
```

**⚠️ Alternative: Use TrueNAS Shell (Safer)**

If TrueNAS has a built-in resize tool:
1. Go to **Storage** → **Pools** → **boot-pool**
2. Look for **Resize** or **Edit** option
3. Set size to 50GB
4. Apply changes

**Note**: TrueNAS may not have this feature. If not, manual partitioning is required.

### Step 6: Create New Partition for fast-pool

**After resizing boot-pool partition:**
```bash
# Create new partition for fast-pool (uses remaining space)
# Using parted:
sudo parted /dev/nvme0n1
# In parted:
# (parted) mkpart primary 50GB 100%
# (parted) set 3 type 6E21 (ZFS partition type)
# (parted) print
# (parted) quit

# Or using fdisk:
# sudo fdisk /dev/nvme0n1
# Create new partition starting at 50GB, using all remaining space
# Set partition type to "Solaris /usr & Apple ZFS" (type 6E)

# Verify new partition
sudo parted /dev/nvme0n1 print
# Should show:
# 1: 512MB (EFI boot)
# 2: 50GB (boot-pool - resized)
# 3: ~880GB (new partition for fast-pool)
```

### Step 7: Re-import Boot-Pool

**Import boot-pool back:**
```bash
# Import boot-pool (system becomes read-write again)
sudo zpool import boot-pool

# Verify boot-pool is working
sudo zpool status boot-pool
sudo zpool list boot-pool
# Should show ~50GB total, ~5-10GB used
```

**System should be back to normal now!**

### Step 8: Create fast-pool on New Partition

**Via TrueNAS Web UI (Recommended):**
1. Go to **Storage** → **Pools** → **Add Pool**
2. **Pool Name**: `fast-pool`
3. **Data VDEVs**:
   - **Type**: Stripe (single device)
   - **Disks**: Select the new partition (should show as available)
   - Should be ~800GB+
4. **Create Pool**

**Via SSH (Alternative):**
```bash
# Find the new partition
sudo lsblk /dev/nvme0n1
# Should show nvme0n1p3 as the new partition

# Create fast-pool (replace nvme0n1p3 with actual partition)
# Note: Use the partition, not the whole disk
sudo zpool create fast-pool /dev/nvme0n1p3

# Verify
sudo zpool list fast-pool
sudo zpool status fast-pool
# Should show ~800GB+ available
```

### Step 9: Create Dataset for Factorio

**Via TrueNAS Web UI:**
1. Go to **Storage** → **Pools** → **fast-pool**
2. **Add Dataset** → **Name**: `apps`
3. **Add Dataset** → **Name**: `factorio` (under apps)
4. **Set Permissions**: `apps:apps` (568:568)

**Via SSH:**
```bash
# Create datasets
sudo zfs create fast-pool/apps
sudo zfs create fast-pool/apps/factorio

# Set permissions
sudo chown -R apps:apps /mnt/fast-pool/apps/factorio
sudo chmod 755 /mnt/fast-pool/apps/factorio
```

### Step 10: Verify Everything Works

**Check pools:**
```bash
sudo zpool list
# Should show:
# boot-pool  ~50GB  (resized)
# tank       ~1.8TB (unchanged)
# fast-pool  ~800GB (new!)

sudo zpool status
# All pools should be ONLINE
```

**Test Factorio path:**
```bash
ls -la /mnt/fast-pool/apps/factorio
# Should exist and be writable
```

## Recovery Plan (If Something Goes Wrong)

### If Boot-Pool Won't Import

1. **Boot from TrueNAS installer USB**
2. **Select "Shell" option**
3. **Import boot-pool:**
   ```bash
   zpool import -f boot-pool
   ```
4. **If that fails, restore from backup:**
   ```bash
   # Restore partition table (Linux)
   sudo sfdisk /dev/nvme0n1 < /tmp/nvme0n1.backup
   # Or if using parted backup:
   # sudo parted /dev/nvme0n1 < /tmp/nvme0n1.backup
   zpool import boot-pool
   ```

### If System Won't Boot

1. **Boot from TrueNAS installer USB**
2. **Reinstall TrueNAS** (last resort)
3. **Import existing pools** after reinstall

## Safer Alternative: Use TrueNAS Web UI (If Available)

**Check if TrueNAS has built-in partitioning:**
1. Go to **Storage** → **Disks**
2. Click on NVMe drive
3. Look for **Partition** or **Edit** options
4. If available, use UI to resize/create partitions

**This is safer** than manual partitioning but may not be available.

## Summary

**Steps:**
1. ✅ Check boot-pool usage (~5-10GB used)
2. ⚠️ Export boot-pool (system read-only)
3. ⚠️ Resize boot-pool partition to 50GB
4. ✅ Create new partition for fast-pool (~800GB)
5. ✅ Re-import boot-pool (system read-write)
6. ✅ Create fast-pool on new partition
7. ✅ Create datasets and set permissions
8. ✅ Verify everything works

**Result:**
- boot-pool: 50GB (plenty for OS)
- fast-pool: ~800GB (for apps like Factorio)
- NVMe fully utilized!

## Next Steps After fast-pool Created

1. ✅ Update Factorio YAML to use `/mnt/fast-pool/apps/factorio`
2. ✅ Deploy Factorio app
3. ✅ Enjoy NVMe-speed performance!

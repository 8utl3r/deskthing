# Step-by-Step NVMe Partitioning Walkthrough

## Prerequisites Checklist

Before starting, make sure you have:
- [ ] TrueNAS installer USB ready (for recovery if needed)
- [ ] Console/KVM access to NAS (system will be read-only during resize)
- [ ] Backup of important data
- [ ] Maintenance window scheduled

---

## Step 1: Check Current Boot-Pool Usage

**Goal:** Verify how much space boot-pool actually uses

**Via SSH:**
```bash
ssh pete@192.168.0.158
sudo zpool list boot-pool
sudo zfs list boot-pool
```

**What to look for:**
- Total size: Should be ~931GB
- Used: Should be ~5-10GB
- Available: Should be ~920GB+ (this is what we'll use for fast-pool)

**✅ If you see ~5-10GB used, you're good to proceed!**

**Tell me what you see, and we'll continue to Step 2.**

---

## Step 2: Check Current Partition Layout

**Goal:** See the current partition structure

**Via SSH:**
```bash
sudo fdisk -l /dev/nvme0n1
sudo lsblk /dev/nvme0n1
```

**What to look for:**
- `nvme0n1p1`: Small partition (~512MB) - EFI boot
- `nvme0n1p2`: Large partition (~930GB) - boot-pool

**✅ Confirm you see partition 2 is ~930GB**

**Tell me what you see, and we'll continue to Step 3.**

---

## Step 3: Backup Partition Table

**Goal:** Create a safety backup before making changes

**Via SSH:**
```bash
# Create backup
sudo sfdisk -d /dev/nvme0n1 > /tmp/nvme0n1.backup

# Verify backup was created
ls -lh /tmp/nvme0n1.backup

# Show backup contents (optional)
cat /tmp/nvme0n1.backup
```

**✅ Backup created! Save this file somewhere safe (copy to your Mac if possible)**

**Tell me when backup is done, and we'll continue to Step 4.**

---

## Step 4: Export Boot-Pool ⚠️

**Goal:** Export boot-pool so we can resize its partition

**⚠️ WARNING: After this, system will be READ-ONLY until we re-import!**

**Via SSH:**
```bash
# Export boot-pool
sudo zpool export boot-pool

# Verify it's exported (boot-pool should NOT appear)
sudo zpool list
```

**What happens:**
- System continues running (read-only)
- Web UI may become unresponsive
- SSH still works (read-only)
- You can still access console

**✅ Boot-pool exported. System is now read-only.**

**⚠️ If something goes wrong, you can re-import: `sudo zpool import boot-pool`**

**Tell me when export is complete, and we'll continue to Step 5.**

---

## Step 5: Resize Boot-Pool Partition ⚠️

**Goal:** Shrink partition 2 from ~930GB to 50GB

**⚠️ CRITICAL STEP - This modifies the partition table!**

**Via SSH (interactive):**
```bash
# Open parted
sudo parted /dev/nvme0n1

# In parted, run these commands:
(parted) print                    # Show current layout
(parted) resizepart 2 50GB        # Resize partition 2 to 50GB
(parted) print                    # Verify new size
(parted) quit                     # Exit parted
```

**What to expect:**
- Before: Partition 2 is ~930GB
- After: Partition 2 is 50GB
- Remaining space: ~880GB (unallocated, ready for new partition)

**✅ Partition resized!**

**Tell me when resize is complete, and we'll continue to Step 6.**

---

## Step 6: Create New Partition for fast-pool

**Goal:** Create partition 3 using the remaining ~880GB

**Via SSH (interactive):**
```bash
# Open parted again
sudo parted /dev/nvme0n1

# In parted, run these commands:
(parted) print                    # Show current layout
(parted) mkpart primary 50GB 100% # Create partition from 50GB to end
(parted) set 3 type 6E21           # Set partition type to ZFS (6E21)
(parted) print                    # Verify new partition
(parted) quit                     # Exit parted
```

**What to expect:**
- Partition 1: ~512MB (EFI boot)
- Partition 2: 50GB (boot-pool - resized)
- Partition 3: ~880GB (new partition for fast-pool)

**✅ New partition created!**

**Tell me when partition is created, and we'll continue to Step 7.**

---

## Step 7: Verify New Partition

**Goal:** Confirm the partition layout is correct

**Via SSH:**
```bash
# Check with parted
sudo parted /dev/nvme0n1 print

# Check with lsblk
sudo lsblk /dev/nvme0n1

# Check with fdisk
sudo fdisk -l /dev/nvme0n1
```

**What to verify:**
- ✅ Partition 2 is 50GB (boot-pool)
- ✅ Partition 3 exists and is ~880GB
- ✅ All partitions show correct sizes

**✅ Partition layout verified!**

**Tell me when verification is complete, and we'll continue to Step 8.**

---

## Step 8: Re-import Boot-Pool

**Goal:** Import boot-pool back (system becomes read-write again)

**Via SSH:**
```bash
# Import boot-pool
sudo zpool import boot-pool

# Verify boot-pool is working
sudo zpool status boot-pool
sudo zpool list boot-pool
```

**What to expect:**
- boot-pool should show ~50GB total
- boot-pool should show ~5-10GB used
- System should be read-write again
- Web UI should work again

**✅ Boot-pool re-imported! System back to normal.**

**Tell me when import is complete, and we'll continue to Step 9.**

---

## Step 9: Create fast-pool

**Goal:** Create ZFS pool on the new partition

**Option A: Via TrueNAS Web UI (Recommended)**
1. Go to **Storage** → **Pools** → **Add Pool**
2. **Pool Name**: `fast-pool`
3. **Data VDEVs**:
   - **Type**: Stripe (single device)
   - **Disks**: Select the new partition (should show as available, ~880GB)
4. **Create Pool**

**Option B: Via SSH**
```bash
# Find the new partition
sudo lsblk /dev/nvme0n1
# Should show nvme0n1p3

# Create fast-pool
sudo zpool create fast-pool /dev/nvme0n1p3

# Verify
sudo zpool list fast-pool
sudo zpool status fast-pool
```

**✅ fast-pool created!**

**Tell me when fast-pool is created, and we'll continue to Step 10.**

---

## Step 10: Create Datasets and Set Permissions

**Goal:** Create Factorio dataset with correct permissions

**Option A: Via TrueNAS Web UI**
1. Go to **Storage** → **Pools** → **fast-pool**
2. **Add Dataset** → **Name**: `apps`
3. **Add Dataset** → **Name**: `factorio` (under apps)
4. **Edit Permissions**: Set to `apps:apps` (568:568)

**Option B: Via SSH**
```bash
# Create datasets
sudo zfs create fast-pool/apps
sudo zfs create fast-pool/apps/factorio

# Set permissions
sudo chown -R apps:apps /mnt/fast-pool/apps/factorio
sudo chmod 755 /mnt/fast-pool/apps/factorio

# Verify
sudo zfs list fast-pool
ls -la /mnt/fast-pool/apps/factorio
```

**✅ Datasets created and permissions set!**

---

## Step 11: Final Verification

**Goal:** Verify everything is working

**Via SSH:**
```bash
# Check all pools
sudo zpool list

# Should show:
# boot-pool  ~50GB  (resized)
# tank       ~1.8TB (unchanged)
# fast-pool  ~880GB (new!)

# Check pool status
sudo zpool status

# All pools should be ONLINE

# Test Factorio path
ls -la /mnt/fast-pool/apps/factorio
# Should exist and be writable
```

**✅ Everything verified!**

---

## Summary

**What we accomplished:**
- ✅ Shrunk boot-pool from 931GB → 50GB
- ✅ Created fast-pool with ~880GB
- ✅ Created datasets for Factorio
- ✅ Set correct permissions

**Next steps:**
1. ✅ Update Factorio YAML to use `/mnt/fast-pool/apps/factorio`
2. ✅ Deploy Factorio app
3. ✅ Enjoy NVMe-speed performance!

---

## Recovery Plan (If Something Goes Wrong)

### If Boot-Pool Won't Import

```bash
# Boot from TrueNAS installer USB
# Select "Shell" option
zpool import -f boot-pool
```

### If Partition Table is Corrupted

```bash
# Restore from backup
sudo sfdisk /dev/nvme0n1 < /tmp/nvme0n1.backup
zpool import boot-pool
```

### If System Won't Boot

1. Boot from TrueNAS installer USB
2. Reinstall TrueNAS (last resort)
3. Import existing pools after reinstall

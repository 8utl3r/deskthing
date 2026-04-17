# Creating fast-pool on NVMe for Factorio

## Overview

Create a fast ZFS pool on NVMe for applications like Factorio. This will give you NVMe-level performance without mixing app data with the OS boot-pool.

## Current Situation

- **NVMe**: 931GB total
- **boot-pool**: Uses entire NVMe (but only 5.60GB actually used)
- **Goal**: Create fast-pool using unused NVMe space

## ⚠️ Important Notes

- This operation is **safe** if done via TrueNAS Web UI
- boot-pool will remain intact (it only needs ~50GB)
- We'll use TrueNAS's built-in partitioning (safer than manual)
- Factorio will get NVMe speed once fast-pool is created

## Step-by-Step: Create fast-pool

### Step 1: Check Current Pools

1. **In TrueNAS Web UI:**
   - Go to **Storage** → **Pools**
   - Note existing pools: `boot-pool` and `tank`

### Step 2: Check Available Disks

1. **Go to:** **Storage** → **Disks**
2. **Look for:** NVMe drive (should show as `nvme0n1` or similar)
3. **Note:** The entire drive is allocated to boot-pool, but TrueNAS may allow creating a new pool

### Step 3: Create fast-pool (TrueNAS Web UI Method)

**Option A: If TrueNAS Shows Available Space**

1. **Go to:** **Storage** → **Pools** → **Add Pool**
2. **Pool Name:** `fast-pool`
3. **Encryption:** Leave default (or enable if you want)
4. **Data VDEVs:**
   - **Type:** Stripe (single device - no redundancy)
   - **Disks:** Select the NVMe drive
   - **Note:** TrueNAS may show it as available if it can partition automatically
5. **Review:** Check configuration
6. **Create Pool**

**Option B: If NVMe Not Available (Manual Partitioning Required)**

If TrueNAS doesn't show the NVMe as available, we need to partition it first. This is more complex but can be done safely.

### Step 4: Verify fast-pool Created

1. **Go to:** **Storage** → **Pools**
2. **Verify:** `fast-pool` appears in the list
3. **Check size:** Should show ~700-800GB (depending on how much space was allocated)

### Step 5: Create Dataset for Factorio

1. **Go to:** **Storage** → **Pools** → **fast-pool**
2. **Click:** **Add Dataset**
3. **Name:** `apps`
4. **Type:** Filesystem
5. **Create**

Then create sub-dataset:
1. **Go to:** **fast-pool** → **apps**
2. **Click:** **Add Dataset**
3. **Name:** `factorio`
4. **Create**

**Result:** `/mnt/fast-pool/apps/factorio` will be available

### Step 6: Set Permissions

1. **Go to:** **Storage** → **Pools** → **fast-pool** → **apps** → **factorio**
2. **Click:** **Edit Permissions**
3. **Set:**
   - **User:** `apps` (or `568`)
   - **Group:** `apps` (or `568`)
   - **Mode:** `755` or `750`
4. **Apply**

Or via SSH:
```bash
ssh pete@192.168.0.158
sudo chown -R apps:apps /mnt/fast-pool/apps/factorio
sudo chmod 755 /mnt/fast-pool/apps/factorio
```

## Alternative: If TrueNAS Doesn't Allow Direct Creation

If TrueNAS won't let you create a pool on the NVMe (because it's fully allocated to boot-pool), you have two options:

### Option 1: Use TrueNAS Shell (Advanced)

This requires SSH access and careful partitioning. **Only do this if you're comfortable with command-line operations.**

```bash
# SSH to NAS
ssh pete@192.168.0.158

# Check current partition layout
sudo fdisk -l /dev/nvme0n1
sudo lsblk /dev/nvme0n1

# This is complex - we'll need to:
# 1. Create a new partition on NVMe
# 2. Create ZFS pool on that partition
# 3. This is risky and requires careful execution
```

**⚠️ Warning:** Manual partitioning can corrupt boot-pool if done incorrectly. Consider Option 2 first.

### Option 2: Use boot-pool Temporarily (Simpler)

If partitioning is too complex, you can:
1. Use `/mnt/boot-pool/apps/factorio` for now
2. Create fast-pool later during a maintenance window
3. Migrate Factorio data later

## Verification

After creating fast-pool:

```bash
# Check pools
sudo zpool list

# Should show:
# boot-pool  (OS)
# tank       (SATA data)
# fast-pool  (NVMe apps) ← NEW

# Check fast-pool status
sudo zpool status fast-pool

# Check dataset exists
ls -la /mnt/fast-pool/apps/factorio
```

## Next Steps

Once fast-pool is created:

1. ✅ Update Factorio YAML to use `/mnt/fast-pool/apps/factorio`
2. ✅ Deploy Factorio app
3. ✅ Enjoy NVMe-speed performance!

## Troubleshooting

### "No available disks" error

**Cause:** TrueNAS sees entire NVMe as used by boot-pool.

**Solution:** 
- Try Option 2 (use boot-pool temporarily)
- Or wait for maintenance window to partition manually
- Or check if TrueNAS has a "partition" option in pool creation

### Permission denied errors

**Solution:**
```bash
sudo chown -R apps:apps /mnt/fast-pool/apps/factorio
sudo chmod 755 /mnt/fast-pool/apps/factorio
```

### Pool creation fails

**Cause:** Insufficient space or partitioning issue.

**Solution:**
- Check boot-pool usage: `sudo zpool list boot-pool`
- Verify NVMe has free space
- Try creating smaller pool first (e.g., 500GB instead of 700GB)

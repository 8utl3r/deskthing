# TrueNAS NVMe Optimization - Step-by-Step Implementation

## Current Situation
- **NVMe**: 931.5 GB total, all used by boot-pool
- **Boot-pool usage**: Only 5.60 GB used
- **Goal**: Create fast-pool (700GB) + L2ARC (200GB)

## ⚠️ Important Note

Since the entire NVMe is allocated to boot-pool, we have two options:

### Option 1: Use TrueNAS Web UI (Safest) ⭐ Recommended
TrueNAS Web UI can help manage this, but may require manual partitioning first.

### Option 2: Manual Partitioning (Advanced)
Requires careful partitioning to free up space.

## Implementation Plan

### Phase 1: Add L2ARC Cache (Easier)

**Via TrueNAS Web UI**:
1. Go to **Storage → Pools**
2. Click on **tank** pool
3. Click **Add VDEV** (or three dots menu)
4. Select **Cache** as VDEV type
5. TrueNAS will show available disks/partitions
6. If NVMe partition available, select it
7. If not, we'll need to create partition first

**Alternative - File-based L2ARC** (temporary workaround):
```bash
# Create a sparse file for L2ARC (not ideal, but works)
sudo truncate -s 200G /mnt/tank/l2arc-cache
sudo zpool add tank cache /mnt/tank/l2arc-cache
```

### Phase 2: Create Fast Pool (Requires Partitioning)

Since entire NVMe is used, we need to:

1. **Create new partition** on NVMe (requires shrinking boot-pool partition)
2. **Create new ZFS pool** on that partition

**⚠️ WARNING**: This is risky and requires:
- Backup of boot-pool
- Careful partitioning
- Potential system downtime

## Safer Alternative Approach

Instead of manually partitioning, let's use a **hybrid approach**:

### Step 1: Add L2ARC Using File (Temporary)

```bash
# Create 200GB file on tank pool for L2ARC
sudo truncate -s 200G /mnt/tank/l2arc-cache
sudo zpool add tank cache /mnt/tank/l2arc-cache
```

**Pros**: 
- ✅ Safe, no partitioning needed
- ✅ Can be removed easily
- ✅ Works immediately

**Cons**:
- ⚠️ Uses space on tank pool (but tank has plenty)
- ⚠️ Not as fast as NVMe directly, but still helps

### Step 2: Create Fast Pool Later (When We Can Partition Safely)

For now, we can:
1. Use L2ARC file approach (Step 1)
2. Plan fast-pool creation for later (when we can safely partition)

## Recommended Immediate Action

**For now, let's**:
1. ✅ Add L2ARC using file-based approach (safe, works now)
2. ⏭️ Plan fast-pool creation for later (requires partitioning)

This gives us the performance benefits of L2ARC immediately, and we can add the fast-pool when we can safely partition the NVMe.

## Commands for File-Based L2ARC

```bash
# 1. Create 200GB sparse file
sudo truncate -s 200G /mnt/tank/l2arc-cache

# 2. Add as cache to tank pool
sudo zpool add tank cache /mnt/tank/l2arc-cache

# 3. Verify it's added
sudo zpool status tank

# 4. Monitor cache performance
sudo zpool iostat -v tank 1
```

## Fast Pool Creation (Future)

When ready to create fast-pool:
1. Backup boot-pool configuration
2. Use `gpart` to shrink boot-pool partition
3. Create new partition for fast-pool
4. Create ZFS pool on new partition
5. Move app storage to fast-pool

---

**Recommendation**: Start with file-based L2ARC now, plan fast-pool for later.

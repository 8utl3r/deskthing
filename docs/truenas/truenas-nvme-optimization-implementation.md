# TrueNAS NVMe Optimization Implementation Guide

## Current Situation

**NVMe Drive**: 931.5 GB total
- `nvme0n1p1`: 1 MB (BIOS boot)
- `nvme0n1p2`: 512 MB (EFI System)
- `nvme0n1p3`: 931 GB (boot-pool - **entire remaining space**)

**Boot-pool Usage**: Only 5.60 GB used out of 931 GB

## Implementation Strategy

Since the entire NVMe is allocated to boot-pool, we have two options:

### Option A: Use TrueNAS Web UI (Recommended - Safer)

TrueNAS Web UI can help manage this, but we'll need to work with what we have.

### Option B: Manual Partitioning (More Complex)

Requires shrinking boot-pool, which is risky.

## Recommended Approach: Create Partitions from Free Space

Actually, we can't easily shrink a ZFS pool that's in use. The **safest approach** is:

1. **Use TrueNAS to create a new pool on the NVMe** - but this requires free space
2. **Alternative**: Use a portion of the boot-pool for L2ARC (can be done)

## Implementation Steps

### Step 1: Add L2ARC Cache (Easier - Can Do Now)

We can add L2ARC using a file or a partition. Since we can't easily create a new partition, we'll use a **sparse file** approach or wait for TrueNAS to support this better.

**Actually, better approach**: Use TrueNAS Web UI to add cache, which may allow us to use part of the boot-pool or create the partition properly.

### Step 2: Create Fast Pool (Requires Free Space)

Since the entire NVMe is used, we need to either:
1. Shrink boot-pool (risky, requires backup)
2. Use a different approach

## Safer Alternative: Use TrueNAS Web UI

Let's use the TrueNAS Web UI which handles this more safely:

1. **Storage → Pools → Add Pool**
2. TrueNAS will detect available space
3. If no space, we'll need to shrink boot-pool first

## Manual Implementation (Advanced)

If we must do this manually:

### Step 1: Backup Boot-Pool

```bash
# Create backup of boot-pool configuration
sudo zpool export boot-pool
# (Backup would be needed before modifying)
```

### Step 2: Shrink Boot-Pool

This is complex and risky. Better to use TrueNAS UI.

## Recommended: Use TrueNAS Web UI

**Steps via Web UI**:

1. **Go to**: Storage → Pools
2. **Check**: Available disks
3. **If NVMe shows as available**: Create new pool
4. **If not**: We may need to use a different approach

## Alternative: Use L2ARC on Existing Pool

We can add L2ARC to the `tank` pool using a file-based approach or wait for proper partitioning.

## Current Recommendation

**For now, let's**:
1. ✅ Set up monitoring for drive errors (done)
2. ⏭️ Use TrueNAS Web UI to check if we can create a new pool
3. ⏭️ If not possible via UI, we'll need to manually partition (risky)

**Actually, let me check if TrueNAS allows creating pools on the same disk...**

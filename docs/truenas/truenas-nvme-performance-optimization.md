# TrueNAS NVMe Performance Optimization Guide

## Current Situation

**NVMe Drive**: Seagate ZP1000GM30063 (1TB)
- **Total Size**: 931.5 GB
- **Used for OS**: 5.60 GB
- **Available**: 922 GB (~99% unused!)
- **Current Use**: Only boot-pool (TrueNAS OS)

**Storage Pool**: `tank` (mirror of 2x spinning disks)
- **Drives**: 3TB + 2TB in mirror
- **No Cache**: Currently no L2ARC or SLOG configured
- **Performance**: Limited by spinning disk speeds

## Options for Utilizing NVMe Space

### Option 1: L2ARC (Read Cache) ⭐ Recommended

**What it does**: Caches frequently read data on fast NVMe, speeding up read operations.

**Pros**:
- ✅ Significant read performance boost
- ✅ Uses unused NVMe space effectively
- ✅ Automatic - no manual management needed
- ✅ Can be added/removed without data loss

**Cons**:
- ⚠️ Uses some RAM for indexing (with 8GB RAM, limit to ~200-400GB)
- ⚠️ Not useful if you have enough RAM for ARC

**Recommendation**: Allocate 200-400GB for L2ARC

**How to add**:
```bash
# Via TrueNAS Web UI:
# Storage → Pools → tank → Add VDEV → Cache
# Select: nvme0n1p4 (new partition) or create partition first

# Via CLI:
sudo zpool add tank cache /dev/nvme0n1p4
```

### Option 2: SLOG (Write Cache) ⚠️ Use with Caution

**What it does**: Caches synchronous writes (NFS, database transactions) before writing to main pool.

**Pros**:
- ✅ Dramatically speeds up synchronous writes
- ✅ Small size needed (16-32GB is plenty)

**Cons**:
- ⚠️ **Requires power loss protection (PLP)** for data safety
- ⚠️ Consumer NVMe drives may lose data on power loss
- ⚠️ Only helps with sync writes (async writes bypass it)

**Recommendation**: Only if you have enterprise NVMe with PLP, or accept risk for non-critical data

**How to add**:
```bash
# Create small partition (16-32GB) for SLOG
sudo zpool add tank log /dev/nvme0n1p5
```

### Option 3: Special VDEV (Metadata) ⭐ Great for Many Small Files

**What it does**: Stores filesystem metadata (directory structures, file locations) on fast NVMe.

**Pros**:
- ✅ Speeds up directory listings, file searches
- ✅ Improves performance with many small files
- ✅ Helps with app metadata (Docker, Kubernetes)

**Cons**:
- ⚠️ Requires redundancy (mirror recommended) - but you only have one NVMe
- ⚠️ Can't be removed once added (pool structure change)

**Recommendation**: Consider if you have many small files or want faster app performance

**How to add**:
```bash
# Via TrueNAS Web UI:
# Storage → Pools → tank → Add VDEV → Special
# Note: Requires at least 2 devices for redundancy (you'd need another NVMe)
```

### Option 4: Separate Fast Pool for Apps/VMs ⭐ Best for App Performance

**What it does**: Create a separate ZFS pool on NVMe for applications, VMs, and containers.

**Pros**:
- ✅ Fastest option for app storage
- ✅ Keeps apps separate from data
- ✅ Can use remaining space (800GB+)
- ✅ No impact on main data pool

**Cons**:
- ⚠️ No redundancy (single drive)
- ⚠️ Apps would need to be reconfigured to use new pool

**Recommendation**: **Best option** if you want maximum app performance

**How to create**:
```bash
# Create new partition on NVMe (use remaining space)
# Via TrueNAS Web UI:
# Storage → Pools → Add Pool
# Name: fast-pool
# Type: Stripe (single device)
# Select: nvme0n1p4 (new partition)
```

### Option 5: Hybrid Approach (Recommended) ⭐⭐⭐

**Best of all worlds**:
1. **L2ARC**: 200-300GB for read cache
2. **Fast Pool**: 600-700GB for apps/VMs/containers

**Benefits**:
- Read cache speeds up data access
- Fast pool gives apps NVMe performance
- Leaves ~50GB buffer for future needs

## Implementation Steps

### Step 1: Partition NVMe Drive

Currently, the entire NVMe is used for boot-pool. We need to:
1. Shrink boot-pool (it only needs ~50GB)
2. Create new partitions for cache/pool

**⚠️ WARNING**: This requires careful planning and may require backup.

**Safer approach**: Create partition from free space (if boot-pool can be resized)

### Step 2: Choose Your Strategy

**For your use case** (8GB RAM, apps running on TrueNAS):

**Recommended**: **Option 4 (Fast Pool)** + **Option 1 (Small L2ARC)**

1. Create `fast-pool` on NVMe (700GB)
2. Add L2ARC cache (200GB)
3. Move app storage to fast-pool

### Step 3: Move Apps to Fast Pool

After creating fast-pool:
1. Go to Apps → Settings → Advanced Settings
2. Change "Pool" from `tank` to `fast-pool`
3. Apps will use NVMe for storage (much faster)

## Performance Expectations

### Current (Spinning Disks Only)
- **Read**: ~100-150 MB/s
- **Write**: ~100-150 MB/s
- **Random I/O**: ~100-200 IOPS

### With L2ARC (200GB)
- **Cached Reads**: ~2000-3000 MB/s (NVMe speed)
- **Uncached Reads**: Same as before
- **Write**: Same as before

### With Fast Pool (Apps on NVMe)
- **App Storage**: ~2000-3000 MB/s
- **Database Operations**: Much faster
- **Container I/O**: Dramatically improved

## Commands Reference

### Check Current Cache Status
```bash
# Check if L2ARC exists
sudo zpool status tank | grep cache

# Check L2ARC statistics
sudo zpool iostat -v tank
```

### Add L2ARC Cache
```bash
# Create partition first (if needed)
sudo gpart create -s gpt /dev/nvme0n1
sudo gpart add -t freebsd-zfs -a 1m -s 200G -l l2arc /dev/nvme0n1

# Add as cache
sudo zpool add tank cache /dev/nvme0n1p4
```

### Create Fast Pool
```bash
# Via TrueNAS Web UI is recommended
# Or via CLI:
sudo zpool create fast-pool /dev/nvme0n1p5
```

### Monitor Performance
```bash
# Check cache hit rates
sudo zpool iostat -v tank 1

# Check L2ARC usage
sudo zfs get all tank | grep l2arc
```

## Recommendations Summary

**For Your Setup** (8GB RAM, apps on TrueNAS):

1. **Primary**: Create `fast-pool` on NVMe (700GB) for apps
   - Move all app storage to fast-pool
   - Dramatically improves app performance

2. **Secondary**: Add L2ARC cache (200GB)
   - Speeds up frequently accessed data
   - Limited by RAM, so keep it reasonable

3. **Skip**: SLOG (unless you have PLP NVMe)
4. **Skip**: Special VDEV (requires redundancy)

## Next Steps

1. **Backup**: Ensure you have backups before modifying pools
2. **Plan**: Decide on fast-pool vs L2ARC vs both
3. **Implement**: Use TrueNAS Web UI for safety
4. **Monitor**: Watch performance improvements

---

**Note**: Modifying ZFS pools can be risky. Always have backups and test in non-critical scenarios first.

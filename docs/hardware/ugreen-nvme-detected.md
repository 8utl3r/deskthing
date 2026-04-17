# NVMe Drive Detected - Ready for TrueNAS

**Date**: 2025-01-19  
**Status**: ✅ NVMe drive successfully installed and detected

## NVMe Drive Details

- **Device**: `/dev/nvme0n1`
- **Model**: Seagate ZP1000GM30063
- **Size**: 931.5 GB (1 TB formatted)
- **Location**: M.2 Slot 1
- **Status**: ✅ Detected by UGOS

## Current Partition Layout

The drive currently has 2 partitions:
- **nvme0n1p1**: 512 MB (likely boot partition)
- **nvme0n1p2**: 931 GB (likely data partition)

**Note**: These partitions may have been created by UGOS or a previous installation. We'll need to check what's on them and potentially wipe them for TrueNAS installation.

## Next Steps

1. ✅ **NVMe drive installed** - COMPLETE
2. ⏭️ **Check partition contents** (see if anything important is on them)
3. ⏭️ **Backup UGOS firmware** (from eMMC)
4. ⏭️ **Prepare TrueNAS USB installer**
5. ⏭️ **Wipe NVMe partitions** (during TrueNAS installation)
6. ⏭️ **Install TrueNAS Scale** on NVMe
7. ⏭️ **Configure storage and migrate data**

## Commands to Check Partitions

```bash
# Check filesystem types
ssh pete@192.168.0.158 "lsblk -f /dev/nvme0n1"

# Check partition details
ssh pete@192.168.0.158 "sudo fdisk -l /dev/nvme0n1"

# Check if mounted
ssh pete@192.168.0.158 "mount | grep nvme"
```

## TrueNAS Installation Plan

The TrueNAS installer will:
1. Wipe existing partitions on NVMe
2. Create new partitions for TrueNAS
3. Install TrueNAS Scale to NVMe
4. Configure bootloader

This is safe because:
- UGOS remains on eMMC (untouched)
- SATA data drives remain untouched
- Can rollback to UGOS anytime by changing boot order

# Ugreen DXP2800 System Information

**Gathered**: 2025-01-19  
**SSH Access**: ✅ Working (username: `pete`, lowercase)

## System Overview

- **Hostname**: NAS
- **OS**: Debian GNU/Linux 12 (bookworm)
- **Kernel**: Linux 6.12.30+ (x86_64)
- **UGOS Version**: 1.9.0.0075
- **Uptime**: System running normally

## Hardware Details

### CPU
- **Model**: Intel(R) N100
- **Cores**: 4 physical cores, 4 threads
- **Base Frequency**: ~1.7 GHz
- **Max Frequency**: 3.4 GHz
- **Cache**: L1d 128KB, L1i 256KB, L2 2MB, L3 6MB
- **Virtualization**: VT-x supported
- **Features**: AES-NI, AVX2, AVX-VNNI

### Network
- **Primary Interface**: eth0 (enp1s0)
- **MAC Address**: 6c:1f:f7:92:7b:df
- **IP Address**: 192.168.0.158/24
- **Controller**: Intel Corporation Ethernet Controller I226-V (rev 04)
- **Status**: ✅ This network adapter is well-supported by TrueNAS Scale

### Storage Configuration

#### Boot Device (eMMC)
- **Device**: `/dev/mmcblk0`
- **Size**: 29.2GB
- **Partitions**:
  - `mmcblk0p1`: 256MB - `/boot` (vfat)
  - `mmcblk0p2`: 2GB - `/rom` (squashfs)
  - `mmcblk0p3`: 10MB - `/mnt/factory` (ext4)
  - `mmcblk0p4`: 2GB - (squashfs)
  - `mmcblk0p5`: 2GB - [SWAP]
  - `mmcblk0p6`: 4GB - `/ugreen` (ext4)
  - `mmcblk0p7`: 18.9GB - `/overlay` (ext4) - Main system

**Note**: UGOS uses overlay filesystem on eMMC. Boot device is intact and can be preserved.

#### Data Storage (SATA)
- **sda**: 2.7TB disk
  - `sda1`: 15.3GB partition
  - `sda2`: 2.7TB - Linux RAID member (md1)
- **sdb**: 1.8TB disk
  - `sdb1`: 15.3GB partition
  - `sdb2`: 1.8TB - Linux RAID member (md1)
- **RAID**: md1 (RAID1) - 1.8TB
- **LVM**: `ug_927BDF_1759962297_pool1-volume1` - 1.8TB
- **Filesystem**: BTRFS
- **Mount**: `/volume1` and `/home`
- **Usage**: 394MB used / 1.9TB available (1% used)

#### NVMe Slots
- **Status**: ⚠️ **No NVMe drives currently installed**
- **Available**: 2x NVMe M.2 slots (per DXP2800 specs)
- **Note**: Need to install NVMe drive for TrueNAS installation

### Memory
- **Total RAM**: 7.5 GB (8 GB physical)
- **Used**: 1.2 GB
- **Available**: 6.4 GB
- **Swap**: 5.8 GB total
  - eMMC swap: 2 GB (mmcblk0p5)
  - zram: 4x 961 MB = ~3.8 GB
- **Status**: Low usage, plenty available

## Current Configuration Summary

```
Boot:     eMMC (29GB) - UGOS installed
Storage:  2x SATA drives in RAID1 (BTRFS) - 1.8TB usable
NVMe:     Empty slots available
Network:  Intel I226-V (well-supported by TrueNAS)
```

## TrueNAS Installation Plan

### Recommended Approach: Install on NVMe

**Why NVMe:**
- ✅ Preserves UGOS on eMMC (can rollback)
- ✅ Better performance than eMMC
- ✅ Avoids eMMC partition issues
- ✅ Can dual-boot if needed

### Steps Required

1. **Install NVMe Drive**
   - Insert NVMe drive into one of the M.2 slots
   - Verify detection: `lsblk` should show `/dev/nvme0n1`

2. **Backup Current Data** (if needed)
   - Current data is on SATA RAID1 (BTRFS)
   - TrueNAS can import BTRFS, but ZFS is recommended
   - Consider backing up important data

3. **Prepare USB Installer**
   - Download TrueNAS Scale ISO
   - Create bootable USB drive

4. **BIOS Configuration**
   - Disable watchdog timer
   - Set boot order: USB → NVMe → eMMC
   - Use USB 2.0 port (USB 3.0 may cause issues)

5. **Install TrueNAS Scale**
   - Boot from USB
   - Install to NVMe drive
   - Configure network (should auto-detect Intel I226-V)

6. **Post-Installation**
   - Access web UI
   - Configure storage pools
   - Import or migrate data from SATA drives
   - Set up Qdrant for Atlas RAG

## Network Configuration

**Current**: DHCP (192.168.0.158)  
**For TrueNAS**: Can use same IP or configure static

Intel I226-V network adapter is well-supported in TrueNAS Scale, so networking should work out of the box.

## Data Migration Considerations

**Current Setup:**
- SATA drives in RAID1 (md1)
- BTRFS filesystem
- LVM volume group

**TrueNAS Options:**
1. **Import BTRFS** (read-only, not recommended long-term)
2. **Create new ZFS pool** on SATA drives
3. **Migrate data** from BTRFS to ZFS
4. **Keep SATA drives as data storage**, use NVMe for OS only

## Next Steps

1. ✅ **System information gathered** - DONE
2. ⏭️ **Install NVMe drive** (if not already installed)
3. ⏭️ **Backup UGOS firmware** (via SSH)
4. ⏭️ **Prepare TrueNAS USB installer**
5. ⏭️ **Configure BIOS settings**
6. ⏭️ **Install TrueNAS Scale**

## Commands for Future Reference

```bash
# Check NVMe after installation
ssh pete@192.168.0.158 "lsblk | grep nvme"

# Backup UGOS eMMC (requires sudo)
ssh pete@192.168.0.158 "sudo dd if=/dev/mmcblk0 of=/volume1/ugos_backup.img bs=4M status=progress"

# Check network adapter details
ssh pete@192.168.0.158 "lspci | grep -i ethernet"
ssh pete@192.168.0.158 "ethtool eth0"

# Monitor system
ssh pete@192.168.0.158 "free -h && df -h"
```

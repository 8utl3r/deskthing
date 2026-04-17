# Creating fast-pool from USB Installer (Rescue Mode)

## Overview

Boot from TrueNAS installer USB and create fast-pool properly. This allows us to export boot-pool safely.

## Steps

### 1. Boot from USB Installer

- Insert TrueNAS installer USB
- Boot from USB
- Select **Shell** (or **Install/Upgrade** → **Shell**)

### 2. Check Current State

```bash
# Check partition layout
parted /dev/nvme0n1 print

# Check if boot-pool can be imported
zpool import
```

### 3. Import Boot-Pool

```bash
# Import boot-pool (read-only is fine)
zpool import -f boot-pool

# Verify it's imported
zpool list boot-pool
zpool status boot-pool
```

### 4. Export Boot-Pool (This Should Work Now!)

```bash
# Export boot-pool (should work in rescue mode)
zpool export boot-pool

# Verify it's exported (should NOT appear)
zpool list
```

**✅ If export succeeds, proceed to Step 5. If it fails, we may need a different approach.**

### 5. Resize Partition 3 to 50GB

```bash
# Check current layout
parted /dev/nvme0n1 print

# Resize partition 3 to 50GB
parted /dev/nvme0n1 resizepart 3 50GB

# Verify
parted /dev/nvme0n1 print
```

**Expected result:**
- Partition 3 should be 50GB (down from 1000GB)

### 6. Create New Partition for fast-pool

```bash
# Create partition 4 using remaining space
parted /dev/nvme0n1 mkpart primary 50GB 100%

# Set partition type to ZFS
parted /dev/nvme0n1 set 4 type 6E21

# Verify new partition
parted /dev/nvme0n1 print
lsblk /dev/nvme0n1
```

**Expected result:**
- Partition 3: 50GB (boot-pool)
- Partition 4: ~950GB (new partition for fast-pool)

### 7. Re-import Boot-Pool

```bash
# Import boot-pool back
zpool import boot-pool

# Verify it's working
zpool status boot-pool
zpool list boot-pool
```

**Expected result:**
- boot-pool should show ~50GB total
- boot-pool should be ONLINE with no errors

### 8. Create fast-pool

```bash
# Find the new partition
lsblk /dev/nvme0n1
# Should show nvme0n1p4

# Create fast-pool
zpool create fast-pool /dev/nvme0n1p4

# Verify
zpool list fast-pool
zpool status fast-pool
```

**Expected result:**
- fast-pool should show ~950GB
- fast-pool should be ONLINE

### 9. Create Datasets

```bash
# Create datasets for Factorio
zfs create fast-pool/apps
zfs create fast-pool/apps/factorio

# Set permissions
chown -R 568:568 /mnt/fast-pool/apps/factorio
chmod 755 /mnt/fast-pool/apps/factorio

# Verify
zfs list fast-pool
ls -la /mnt/fast-pool/apps/factorio
```

### 10. Verify Everything

```bash
# Check all pools
zpool list

# Should show:
# boot-pool  ~50GB
# tank       ~1.8TB (unchanged)
# fast-pool  ~950GB (new!)

# Check status
zpool status
# All pools should be ONLINE
```

### 11. Reboot

```bash
# Remove USB drive
# Then reboot
reboot
```

**System should boot normally with fast-pool available!**

## Troubleshooting

### Boot-Pool Won't Export

If export still fails in rescue mode:
- Try: `zpool export -f boot-pool`
- Or: `zfs unmount -a -t filesystem boot-pool` then export

### Partition Resize Fails

- Make sure boot-pool is exported first
- Check partition numbers: `parted /dev/nvme0n1 print`

### Fast-Pool Creation Fails

- Verify partition 4 exists: `lsblk /dev/nvme0n1`
- Check partition type: `parted /dev/nvme0n1 print`
- Try: `zpool create -f fast-pool /dev/nvme0n1p4`

## Recovery Plan

If something goes wrong:
1. Restore partition table from backup (if accessible)
2. Or resize partition 3 back to 100%: `parted /dev/nvme0n1 resizepart 3 100%`
3. Import boot-pool: `zpool import boot-pool`
4. Reboot and try again

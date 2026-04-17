# TrueNAS tank Pool Migration: Seagate → WD Red 6TB

## Overview

**Goal**: Migrate the `tank` pool from 2× Seagate drives (3TB + 2TB mirror) to 2× WD6004FZBX-00C9FA0 (WD Red Plus 6TB).

**Current State**:
- **Pool**: `tank` (mirror raid1)
- **sda**: Seagate ST3000DM001-1CH166 (3TB)
- **sdb**: Seagate ST2000VM003-1ET164 (2TB) — has had ATA errors, 3.7 years old
- **Usable**: ~1.81TB (limited by smaller drive)
- **Used**: ~26.3GB
- **L2ARC**: 200GB file-based on tank

**After Migration**:
- **Usable**: ~6TB (both drives 6TB)
- **Pool name**: `tank` (unchanged)
- **Apps**: No reconfiguration needed — they stay on tank

---

## Strategy: Replace-in-Place (One Drive at a Time)

ZFS mirror lets you replace one drive at a time. The pool stays **online and redundant** during the entire process. Replace sdb first (the one with ATA errors), then sda.

---

## Prerequisites

### 1. Backup

Even with mirror redundancy, ensure you have a backup of critical data before starting.

### 2. Verify New Drives

Before migrating, verify the WD drives are detected:

```bash
# SSH to TrueNAS, then:
lsblk
# or
ls -la /dev/sd*
```

You should see the new drives (e.g. sdc, sdd if both are installed, or just one if you're doing one-at-a-time).

### 3. Check Current Pool Status

```bash
sudo zpool status tank
```

Confirm both drives are ONLINE before starting.

---

## Migration Steps

### Phase 1: Replace sdb (2TB Seagate) First

Replace the drive that has had ATA errors.

#### Step 1: Shut Down NAS (if you only have 2 bay slots)

If you have only 2 drive bays, you must:

1. **Shut down** the NAS correctly (System → Shut Down)
2. **Remove** sdb (Seagate ST2000VM003)
3. **Install** first WD 6TB in its place
4. **Power on** and access TrueNAS

If you have extra bays, you can install the new drive and use Replace without shutting down.

#### Step 2: Replace via TrueNAS UI

1. Go to **Storage** → **Storage Dashboard**
2. Click **View VDEVs** for the `tank` pool
3. Expand the mirror VDEV
4. Click on **sdb** (or the disk slot that had the 2TB Seagate)
5. Click **Replace** in the Disk Info widget
6. In the **Member Disk** dropdown, select the new WD 6TB
7. Leave **Force** unchecked unless the disk has partitions (TrueNAS will wipe it)
8. Click **Replace Disk**

#### Step 3: Wait for Resilver

- TrueNAS will resilver (rebuild the mirror) — typically 1–3 hours for ~26GB
- Monitor: **Storage** → **Storage Dashboard** → tank
- Or via CLI: `sudo zpool status tank`

When resilver completes, the first WD 6TB will be part of the mirror. Pool remains at ~1.81TB usable (limited by sda’s 3TB).

---

### Phase 2: Replace sda (3TB Seagate)

#### Step 1: Shut Down (if 2-bay system)

1. **Shut down** the NAS
2. **Remove** sda (Seagate ST3000DM001)
3. **Install** second WD 6TB
4. **Power on**

#### Step 2: Replace via TrueNAS UI

1. **Storage** → **Storage Dashboard** → **View VDEVs** for `tank`
2. Expand the mirror VDEV
3. Click on **sda** (the 3TB Seagate)
4. Click **Replace**
5. Select the second WD 6TB
6. Click **Replace Disk**

#### Step 3: Wait for Resilver

- Resilver again for ~26GB
- After completion, both mirrors are 6TB drives

#### Step 4: Pool Expansion

ZFS will automatically expand the pool to use the full 6TB. No extra steps. Verify:

```bash
sudo zpool list tank
# capacity should show ~6TB
```

---

## Post-Migration

### 1. Verify Pool Health

```bash
sudo zpool status tank
# Both drives should show ONLINE
```

### 2. L2ARC

The L2ARC cache at `/mnt/tank/l2arc-cache` remains on the pool. It will warm up again as data is read. No action needed.

### 3. Apps

Apps on `tank` keep working because the pool name and paths are unchanged.

### 4. Optional: Wipe Old Drives

Before reuse or disposal, wipe the old Seagates:

- **Storage** → **Disks** → select disk → **Wipe**

---

## Timing

| Phase   | Action           | Typical duration |
|---------|------------------|------------------|
| Phase 1 | Replace sdb      | 1–3 hours resilver |
| Phase 2 | Replace sda      | 1–3 hours resilver |
| Total   | Both replacements | ~2–6 hours       |

---

## Troubleshooting

### "Replace" option not visible

- Ensure the new disk is detected and not in another pool
- Check **Storage** → **Disks** for the new drive

### Disk shows partitions / replacement blocked

- Use **Force** in the Replace dialog so TrueNAS can wipe the disk
- Only use Force if you are sure the disk has no needed data

### Resilver very slow

- Normal during resilver; avoid heavy I/O
- Check for ATA/disk errors: `dmesg | grep -i ata`

### Pool degraded during replacement

- Expected while one drive is being replaced
- Avoid removing or replacing the other drive until resilver finishes

---

## Reference

- [TrueNAS: Replacing Disks](https://www.truenas.com/docs/scale/scaletutorials/storage/disks/replacingdisks/)
- WD6004FZBX: WD Red Plus 6TB, CMR, NAS-rated

---

**Migration Date**: _To be filled_
**Status**: _To be filled_

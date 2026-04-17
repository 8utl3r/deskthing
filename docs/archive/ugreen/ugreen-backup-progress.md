# UGOS Backup & TrueNAS ISO Download Progress

**Started**: 2025-01-19

## Tasks Running

### 1. UGOS Firmware Backup ✅ Started
- **Source**: `/dev/mmcblk0` (29.2 GB eMMC)
- **Destination**: `/volume1/ugos_backup.img`
- **Size**: ~30 GB (will take 10-30 minutes depending on speed)
- **Status**: Running in background
- **Command**: `sudo dd if=/dev/mmcblk0 of=/volume1/ugos_backup.img bs=4M status=progress`

**Check progress:**
```bash
ssh pete@192.168.0.158 "ls -lh /volume1/ugos_backup.img"
```

**When complete, verify:**
```bash
ssh pete@192.168.0.158 "ls -lh /volume1/ugos_backup.img && file /volume1/ugos_backup.img"
```

### 2. TrueNAS Scale ISO Download ✅ Started
- **Version**: TrueNAS SCALE 25.04.2.4 (Fangtooth) - Stable Release
- **Size**: ~2.15 GB
- **URL**: https://download.truenas.com/TrueNAS-SCALE-Fangtooth/25.04.2.4/TrueNAS-SCALE-25.04.2.4.iso
- **Destination**: `/Users/pete/dotfiles/downloads/TrueNAS-SCALE-25.04.2.4.iso`
- **Status**: Downloading in background

**Check progress:**
```bash
ls -lh ~/dotfiles/downloads/TrueNAS-SCALE-25.04.2.4.iso
```

## Next Steps After Completion

1. ✅ **Verify backup** - Check file size matches eMMC size (~30GB)
2. ✅ **Verify ISO** - Check file size (~2.15GB) and integrity
3. ⏭️ **Create bootable USB** - Use Etcher, Rufus, or `dd` command
4. ⏭️ **Configure BIOS** - Disable watchdog, set boot order
5. ⏭️ **Install TrueNAS** - Boot from USB, install to NVMe

## USB Creation Commands (After ISO Download)

**Using dd (macOS/Linux):**
```bash
# Find USB device (be careful - this will erase the USB!)
diskutil list

# Unmount USB (replace /dev/diskX with your USB)
diskutil unmountDisk /dev/diskX

# Write ISO to USB (replace /dev/rdiskX with your USB)
sudo dd if=~/dotfiles/downloads/TrueNAS-SCALE-25.04.2.4.iso of=/dev/rdiskX bs=1m status=progress

# Eject USB
diskutil eject /dev/diskX
```

**Using Etcher (Recommended - GUI tool):**
- Download Etcher: https://etcher.balena.io/
- Select ISO file
- Select USB drive
- Flash

## Notes

- Backup is stored on SATA storage (`/volume1`) - safe even after OS replacement
- ISO download may take 5-15 minutes depending on internet speed
- Backup may take 10-30 minutes depending on eMMC speed
- Both processes are running in background

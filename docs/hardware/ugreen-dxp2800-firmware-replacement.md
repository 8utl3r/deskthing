# Ugreen DXP2800 Firmware Replacement Guide

## Overview

This guide documents the plan to replace UGOS (stock firmware) on the Ugreen DXP2800 NAS with a privacy-focused alternative firmware to eliminate phone-home behavior.

**Device Details:**
- **Model**: Ugreen DXP2800
- **IP Address**: 192.168.0.158
- **MAC Address**: 6c:1f:f7:92:7b:df
- **SSH Access**: ✅ Working (username: `pete`, lowercase)
- **Current OS**: UGOS 1.9.0.0075 (Debian 12 based)
- **Boot Device**: 29.2GB eMMC (internal) - `/dev/mmcblk0`
- **Storage**: 
  - 2x SATA drives (2.7TB + 1.8TB) in RAID1, BTRFS
  - 2x NVMe slots (currently empty - need to install for TrueNAS)
- **Network**: Intel I226-V (well-supported by TrueNAS)

## Why Replace Firmware?

**Privacy Concerns:**
- UGOS includes phone-home telemetry and cloud connectivity
- Data collection and usage reporting to Ugreen servers
- Limited control over network communications

**Goals:**
- ✅ Eliminate phone-home behavior
- ✅ Full control over network communications
- ✅ Use proven, open-source NAS software
- ✅ Maintain data integrity and functionality

## Firmware Options

### Option 1: TrueNAS Scale (Recommended for Features)

**Pros:**
- ✅ ZFS filesystem with advanced features
- ✅ Docker/Kubernetes support
- ✅ Excellent web UI
- ✅ Large community and documentation
- ✅ Many users successfully running on DXP2800

**Cons:**
- ⚠️ Some phone-home behavior (can be disabled)
- ⚠️ Requires blocking `usage.truenas.com` via firewall/DNS
- ⚠️ More resource-intensive than OMV

**Privacy Configuration:**
- Disable "Usage Collection" in Global Network/Statistics settings
- Block `usage.truenas.com` via firewall or hosts file
- Monitor network connections to ensure no telemetry

### Option 2: OpenMediaVault (Recommended for Privacy)

**Pros:**
- ✅ Minimal telemetry by default
- ✅ Lightweight and efficient
- ✅ Debian-based (privacy-conscious defaults)
- ✅ Fully open-source and inspectable
- ✅ Easy to disable any external communications

**Cons:**
- ⚠️ Less feature-rich than TrueNAS
- ⚠️ Smaller community than TrueNAS
- ⚠️ More manual configuration required

**Privacy Configuration:**
- Disable plugin repositories if not needed
- Block update servers if desired
- Monitor network connections

## Installation Strategy

### Recommended Approach: Install on NVMe (Preserve Stock Firmware)

**Why NVMe instead of eMMC:**
- Preserves stock UGOS firmware for rollback
- Avoids eMMC partition issues
- Better performance
- Easier to manage multiple OS installations

**Steps:**
1. Install alternative OS on NVMe drive
2. Keep eMMC with UGOS intact
3. Use BIOS boot order to select OS
4. Can switch back to UGOS if needed

### Alternative: Install on eMMC (Replace Stock Firmware)

**Warning:** This permanently replaces UGOS. Only do this if:
- You have a full backup of UGOS
- You're certain you won't need stock firmware
- You understand warranty implications

## Pre-Installation Checklist

### 1. Enable SSH on UGOS

**Via Web UI:**
1. Access `http://192.168.0.158`
2. Control Panel → Terminal → Enable SSH Service
3. Note: Default port 22, can change if needed

**Verify SSH Access:**
```bash
ssh admin@192.168.0.158
# Use admin credentials, then: sudo -i
```

### 2. Backup Stock Firmware (Via SSH)

**Option A: Backup via SSH (if UGOS allows)**
```bash
# SSH into UGOS
ssh admin@192.168.0.158
sudo -i

# Identify eMMC device
lsblk | grep mmcblk0

# Create backup to external USB drive or network share
dd if=/dev/mmcblk0 of=/mnt/usb/ugos_backup.img bs=4M status=progress

# Or backup to network share
dd if=/dev/mmcblk0 | ssh user@your-mac "cat > ~/ugos_backup.img"
```

**Option B: Backup via Linux USB Live Environment**
```bash
# Boot from Linux USB live environment
# Identify eMMC device
lsblk | grep mmcblk0

# Create full backup
dd if=/dev/mmcblk0 of=/path/to/external/usb/ugos_backup.img bs=4M status=progress

# Verify backup
ls -lh /path/to/external/usb/ugos_backup.img
```

### 3. Check Hardware via SSH

```bash
# SSH into UGOS
ssh admin@192.168.0.158
sudo -i

# List all disks
lsblk

# Check NVMe slots
lspci | grep -i nvme
ls -la /dev/nvme*

# Check network interfaces
ip addr show
# Should show Intel I226-V or similar

# Check BIOS/UEFI info
dmidecode -t system
```

### 2. Prepare Installation Media

**For TrueNAS Scale:**
- Download TrueNAS Scale ISO (recommend version 24.04 for DXP2800 compatibility)
- Write to USB using Etcher, Rufus, or `dd`
- Use USB 2.0 port (USB 3.0 may cause installer crashes)

**For OpenMediaVault:**
- Download OMV ISO (latest Debian-based version)
- Write to USB using Etcher or `dd`
- Use USB 2.0 port

### 3. BIOS Configuration

**Critical BIOS Settings:**
1. **Disable Watchdog Timer** (required - prevents forced reboots)
   - Advanced → Watchdog → Disable
   
2. **Change Boot Order**
   - USB → NVMe → eMMC (if installing on NVMe)
   - USB → eMMC (if replacing eMMC)

3. **Optional: Disable eMMC** (if installing on NVMe)
   - Advanced → Storage → Disable eMMC
   - Prevents boot conflicts

4. **Secure Boot**: Disable (if present)

**BIOS Access:**
- Boot and press **Ctrl + F12** (or appropriate key for DXP2800)
- Check Ugreen documentation for exact key combination

## Remote Installation via SSH

### Can Installation Be Done Via SSH?

**Short Answer:** Partially yes, but requires initial USB boot.

**What CAN be done via SSH:**
- ✅ Enable SSH on UGOS (via web UI first)
- ✅ Backup UGOS firmware via SSH
- ✅ Prepare installation media and check hardware
- ✅ Post-installation configuration (once TrueNAS is installed)
- ✅ All ongoing management via SSH

**What CANNOT be done via SSH:**
- ❌ Initial TrueNAS installer boot (requires USB boot)
- ❌ BIOS configuration (requires physical access or IPMI)
- ❌ Bootloader installation (happens during USB boot)

**Hybrid Approach (Recommended):**
1. Enable SSH on UGOS via web UI
2. Use SSH to backup and prepare
3. Boot from USB (one-time physical access needed)
4. Use TrueNAS Connect (web installer) for remote installation
5. Complete setup via SSH/web UI

### Step 1: Enable SSH on UGOS

**Via Web UI:**
1. Log into `http://192.168.0.158` (or web interface)
2. Navigate to **Control Panel** → **Terminal**
3. Enable **SSH Service**
4. Optionally set custom port (default: 22)
5. Save settings

**Verify SSH Access:**
```bash
ssh admin@192.168.0.158
# Use your admin credentials
# Then elevate: sudo -i
```

### Step 2: Prepare via SSH

Once SSH is enabled, you can:
- Backup UGOS firmware
- Check hardware (disks, NVMe slots)
- Prepare installation scripts
- Download TrueNAS ISO

## Installation Steps: TrueNAS Scale

### Step 1: Boot from USB
- Insert USB installer (prepared on your Mac)
- Boot DXP2800 and select USB device
- TrueNAS installer should load

**Remote Option: TrueNAS Connect (Web Installer)**
- If TrueNAS Scale 25.10+ is used, TrueNAS Connect allows web-based installation
- Requires: USB boot, same network, mDNS support
- Access installer via browser instead of local monitor

### Step 2: Install to NVMe (Recommended)

1. Select NVMe drive as installation target
2. Choose "Install/Upgrade" option
3. Set root password
4. Configure network interface (Intel I226-V should work)
5. Complete installation

### Step 3: Post-Installation (All Via SSH/Web UI)

**Initial Network Configuration:**
- TrueNAS will use DHCP initially
- Access web UI at `http://<assigned-ip>` or use Console Setup Menu
- Or SSH in: `ssh root@<assigned-ip>`
- Set static IP: `192.168.0.158` (if desired)

**Console Setup Menu (If Needed):**
```bash
# Access via SSH or local console
/usr/bin/cli --menu
# Configure network, enable SSH, set static IP
```

**Privacy Configuration (Via SSH):**
```bash
# SSH into TrueNAS
ssh root@192.168.0.158

# Block usage.truenas.com via hosts file
echo "0.0.0.0 usage.truenas.com" >> /etc/hosts

# Verify blocking
ping usage.truenas.com
# Should fail or resolve to 0.0.0.0

# Monitor network connections
netstat -an | grep ESTABLISHED
# Check for any unexpected connections
```

**All Further Configuration:**
- ✅ Web UI: `https://192.168.0.158` (after HTTPS setup)
- ✅ SSH: `ssh root@192.168.0.158`
- ✅ TrueNAS CLI: `cli` command via SSH

**Web UI Privacy Settings:**
- System → General → Usage Collection → **Disable**
- System → Network → Disable any cloud services
- Monitor network connections to verify no telemetry

### Step 4: Configure Storage

- Create storage pools from NVMe/SATA drives
- Set up shares (SMB, NFS, etc.)
- Configure Docker/Kubernetes if needed

## Installation Steps: OpenMediaVault

### Step 1: Boot from USB
- Insert USB installer
- Boot and select USB device
- OMV installer should load

### Step 2: Install to NVMe

1. Select NVMe drive as installation target
2. Complete Debian installation process
3. OMV will be installed automatically

### Step 3: Post-Installation

**Access Web UI:**
- Default: `http://192.168.0.158`
- Default credentials: `admin` / `openmediavault`

**Privacy Configuration:**
- System → Update Management → Disable auto-updates if desired
- System → Notification → Disable external notifications
- Monitor network connections

**Storage Configuration:**
- Storage → Disks → Initialize drives
- Storage → File Systems → Create filesystems
- Services → Enable SMB/NFS shares

## Known Issues & Solutions

### Issue: "Failed to find partition number 2 on mmcblk0"

**Solution:**
- Use TrueNAS Scale 24.04 (older version)
- Or install on NVMe instead of eMMC
- Or wipe eMMC: `dd if=/dev/zero of=/dev/mmcblk0 count=1024`

### Issue: Frequent Reboots with Third-Party OS

**Solution:**
- Disable watchdog timer in BIOS (critical!)
- Check BIOS boot order settings

### Issue: USB Installer Crashes

**Solution:**
- Use USB 2.0 port instead of USB 3.0
- Some users report USB 3.0 causes installer freezes

### Issue: Network Interface "No Carrier"

**Solution:**
- Intel I226-V should work in TrueNAS Scale
- Try different network cable/port
- Check BIOS network settings

### Issue: Losing VGA/HDMI Output

**Solution:**
- These systems are headless after OS replacement
- Access via web UI only
- Monitor/keyboard may work during Linux install

## Privacy Hardening Checklist

### TrueNAS Scale
- [ ] Disable Usage Collection in web UI
- [ ] Block `usage.truenas.com` via hosts file or firewall
- [ ] Monitor network connections: `netstat -an | grep ESTABLISHED`
- [ ] Review firewall rules
- [ ] Disable any cloud sync features

### OpenMediaVault
- [ ] Disable auto-updates if desired
- [ ] Review plugin repositories
- [ ] Monitor network connections
- [ ] Configure firewall rules
- [ ] Disable external notifications

## Rollback Plan

### If Installed on NVMe:
1. Boot into BIOS
2. Change boot order to eMMC first
3. UGOS should boot normally
4. Can switch back anytime

### If Installed on eMMC:
1. Boot from Linux USB
2. Restore UGOS backup: `dd if=ugos_backup.img of=/dev/mmcblk0 bs=4M status=progress`
3. Reboot

## Next Steps

1. **Research Phase** (Current)
   - [x] Identify device and IP
   - [x] Research firmware options
   - [x] Document installation process
   - [x] Choose firmware: **TrueNAS Scale**

2. **Preparation Phase** (Can be done via SSH)
   - [ ] Enable SSH on UGOS via web UI
   - [ ] SSH into UGOS and verify access
   - [ ] Backup current UGOS firmware via SSH
   - [ ] Check hardware (disks, NVMe, network) via SSH
   - [ ] Download TrueNAS Scale ISO (latest version)
   - [ ] Prepare USB installer on Mac
   - [ ] Review BIOS settings (requires physical access)

3. **Installation Phase** (Requires USB Boot)
   - [ ] Physical access: Insert USB installer
   - [ ] Boot DXP2800 from USB
   - [ ] Use TrueNAS Connect (web installer) if available, or local console
   - [ ] Install TrueNAS Scale to NVMe drive
   - [ ] Configure initial network settings
   - [ ] Enable SSH in TrueNAS

4. **Configuration Phase** (All via SSH/Web UI)
   - [ ] SSH into TrueNAS: `ssh root@192.168.0.158`
   - [ ] Configure static IP (if needed)
   - [ ] Configure privacy settings (block usage.truenas.com)
   - [ ] Set up storage pools/shares
   - [ ] Configure Docker/Qdrant for Atlas RAG
   - [ ] Test all functionality

5. **Verification Phase** (All via SSH)
   - [ ] Verify no phone-home behavior
   - [ ] Monitor network connections: `netstat -an | grep ESTABLISHED`
   - [ ] Test storage and sharing
   - [ ] Document final configuration

## Resources

- **TrueNAS Scale**: https://www.truenas.com/truenas-scale/
- **OpenMediaVault**: https://www.openmediavault.org/
- **Reddit Community**: r/UgreenNASync
- **TrueNAS Forums**: https://www.truenas.com/community/

## Notes

- Warranty may be affected by firmware replacement
- Always backup data before making changes
- Keep UGOS backup in safe location
- Test thoroughly before relying on new firmware

---

**Last Updated**: 2025-01-06  
**Status**: Planning Phase  
**Next Action**: Choose firmware option and begin preparation

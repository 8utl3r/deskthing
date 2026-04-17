# TrueNAS Scale Installation Guide - Ugreen DXP2800

**Status**: ✅ TrueNAS installer loaded successfully!

## 🎯 Installation Overview

**What we're doing:**
1. Install TrueNAS Scale to NVMe drive (`/dev/nvme0n1`)
2. Keep UGOS on eMMC intact (for rollback)
3. Configure network and initial setup
4. Access TrueNAS web UI

---

## Step 1: Console Setup Menu

**You should see:** "TrueNAS 25.04.2.4 Console setup"

**Options available:**
- `1` - Configure Network Interfaces
- `2` - Configure Link Aggregation
- `3` - Configure Default Route
- `4` - Configure DNS
- `5` - Configure Static Routes
- `6` - Configure Default Route
- `11` - Shell (for advanced)
- `12` - Reboot System
- `13` - Shutdown System

**For now:** Press `11` to enter Shell (we'll install first, then configure)

---

## Step 2: Start Installation

**In Shell (option 11):**

**Check available disks:**
```bash
lsblk
```

**You should see:**
- `/dev/mmcblk0` - eMMC (UGOS - leave this alone!)
- `/dev/nvme0n1` - NVMe drive (this is our target!)
- `/dev/sda`, `/dev/sdb` - SATA drives (data storage)

**Start TrueNAS installer:**
```bash
install-truenas
```

**Or if that doesn't work:**
```bash
truenas-installer
```

---

## Step 3: Installation Wizard

**The installer will guide you through:**

### 3.1 Select Installation Disk

**Important:** Select **NVMe drive** (`/dev/nvme0n1`)
- **DO NOT** select eMMC (`/dev/mmcblk0`) - that's UGOS!
- **DO NOT** select SATA drives (`/dev/sda`, `/dev/sdb`) - those are data!

**Look for:** `/dev/nvme0n1` or similar
**Select it** and confirm

### 3.2 Confirm Installation

**Warning will appear:** "This will erase all data on the selected disk"
- **Expected** - NVMe will be wiped
- **Confirm** - Yes, proceed

### 3.3 Set Root Password

**Enter a strong password:**
- This is the root/admin password
- You'll use it to log into TrueNAS web UI
- **Save this password!**

### 3.4 Boot Mode

**Select:** UEFI (recommended)
- Or BIOS if UEFI doesn't work
- UEFI is preferred for modern systems

### 3.5 Installation Progress

**Wait for installation to complete:**
- May take 10-20 minutes
- Progress bar will show
- Don't interrupt!

---

## Step 4: Post-Installation

**After installation completes:**

### 4.1 Reboot

**System will prompt to reboot:**
- Remove USB drive
- Reboot system
- TrueNAS should boot from NVMe

### 4.2 Initial Boot

**TrueNAS will boot and show:**
- Console setup menu again
- Network configuration needed
- Web UI URL (usually `http://<ip-address>`)

---

## Step 5: Network Configuration

**Back in Console Setup Menu:**

### 5.1 Configure Network Interface

**Select:** `1` - Configure Network Interfaces

**You should see:**
- `eth0` or `enp1s0` (Intel I226-V)
- Select it
- Choose: `DHCP` or `Static IP`

**For Static IP (recommended):**
- IP: `192.168.0.158` (same as UGOS had)
- Netmask: `255.255.255.0` or `/24`
- Gateway: `192.168.0.1` (your router)

### 5.2 Configure Default Route

**Select:** `3` - Configure Default Route
- Enter gateway: `192.168.0.1`

### 5.3 Configure DNS

**Select:** `4` - Configure DNS
- Enter DNS servers: `8.8.8.8` and `8.8.4.4` (Google DNS)
- Or use your router's DNS

---

## Step 6: Access Web UI

**After network is configured:**

**TrueNAS will display:**
- Web UI URL: `http://192.168.0.158` (or assigned IP)
- Username: `root`
- Password: (the one you set during installation)

**Open in browser:**
- Go to the displayed URL
- Log in with root and password
- TrueNAS web interface should load!

---

## 📋 Quick Reference Commands

**In Console Setup Menu:**
- `1` - Configure Network
- `4` - Configure DNS  
- `11` - Shell
- `12` - Reboot

**In Shell:**
- `lsblk` - List disks
- `install-truenas` - Start installer
- `ip addr show` - Check network

---

## ⚠️ Important Notes

**During Installation:**
- ✅ Select NVMe (`/dev/nvme0n1`) as installation target
- ❌ Do NOT select eMMC (`/dev/mmcblk0`)
- ❌ Do NOT select SATA drives (`/dev/sda`, `/dev/sdb`)
- ✅ Set a strong root password
- ✅ Choose UEFI boot mode

**After Installation:**
- Remove USB drive before rebooting
- TrueNAS will boot from NVMe
- UGOS remains on eMMC (can rollback if needed)
- SATA data drives remain untouched

---

**Ready? Start with Step 1 - what do you see in the Console Setup Menu?**

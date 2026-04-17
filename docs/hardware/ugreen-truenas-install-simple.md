# TrueNAS Installation - Simple Menu Guide

**Menu Options:**
- `1` - Install ✅ (This is what we want!)
- `2` - (likely Shell or System)
- `3` - (likely Reboot)
- `4` - (likely Shutdown)

## 🚀 Installation Steps

### Step 1: Start Installation

**Press `1`** (or type `1` and press Enter)

**This starts the TrueNAS installation wizard**

---

### Step 2: Installation Wizard Will Guide You

**The installer will ask:**

#### 2.1 Select Installation Disk

**You'll see a list of disks:**
- Look for: `/dev/nvme0n1` or `nvme0n1` (your NVMe drive)
- **Select this one!**

**DO NOT select:**
- ❌ `/dev/mmcblk0` or `mmcblk0` (eMMC - that's UGOS!)
- ❌ `/dev/sda` or `sda` (SATA drive - your data!)
- ❌ `/dev/sdb` or `sdb` (SATA drive - your data!)

**How to identify NVMe:**
- Usually shows as `nvme0n1` or similar
- Size should be ~931GB (your 1TB drive)
- May show as "Seagate ZP1000GM30063"

#### 2.2 Confirm Installation

**Warning will appear:** "This will erase all data"
- **Expected** - NVMe will be wiped
- Type `yes` or confirm to proceed

#### 2.3 Set Root Password

**Enter a strong password:**
- This is your admin password
- You'll use it to log into TrueNAS web UI
- **Save this password somewhere safe!**

#### 2.4 Boot Mode

**Select:** `UEFI` (recommended)
- Or `BIOS` if UEFI doesn't work
- UEFI is preferred for modern systems

#### 2.5 Installation Progress

**Wait for installation:**
- May take 10-20 minutes
- Progress bar will show
- **Don't interrupt!**

---

### Step 3: After Installation

**When installation completes:**

1. **Remove USB drive** (important!)
2. **Reboot system**
3. **TrueNAS will boot from NVMe**
4. **Console Setup Menu will appear**
5. **Configure network** (option 1)
6. **Access web UI**

---

## 📋 Quick Checklist

**During Installation:**
- [ ] Selected NVMe drive (`/dev/nvme0n1`)
- [ ] Did NOT select eMMC (`/dev/mmcblk0`)
- [ ] Did NOT select SATA drives (`/dev/sda`, `/dev/sdb`)
- [ ] Set strong root password
- [ ] Selected UEFI boot mode
- [ ] Waited for installation to complete

**After Installation:**
- [ ] Removed USB drive
- [ ] Rebooted system
- [ ] TrueNAS boots from NVMe
- [ ] Configured network
- [ ] Accessed web UI

---

**Ready? Press `1` to start installation!**

**When it asks for installation disk, select the NVMe drive (nvme0n1).**

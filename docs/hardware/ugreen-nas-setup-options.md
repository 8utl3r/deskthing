# Ugreen DXP2800 NAS Setup Options Summary

## 🎯 Your Current Situation

**Hardware:**
- ✅ Ugreen DXP2800 NAS (Intel N100, 8GB RAM)
- ✅ NVMe drive installed (`/dev/nvme0n1`)
- ✅ 2x SATA drives with data (BTRFS RAID1)
- ✅ UGOS running on eMMC
- ✅ Jet KVM for remote access

**Problems:**
- ⚠️ Watchdog timer causes reboots during TrueNAS installation
- ⚠️ Can't access BIOS through Jet KVM (keyboard not recognized)
- ⚠️ TrueNAS installer reboots every few minutes

---

## 🚀 Your Options for Installing TrueNAS

### Option 1: Disable Watchdog via BIOS (Permanent Fix)

**Best if:** You can access BIOS

**Steps:**
1. **Access BIOS** (choose method below):
   - **Method A:** Direct USB keyboard (bypass KVM)
     - Connect simple USB keyboard directly to NAS USB 2.0 port
     - Reboot, press `Ctrl+F2` immediately
     - BIOS should appear
   - **Method B:** JetKVM Virtual Keyboard
     - Open JetKVM web interface
     - Use Virtual Keyboard feature
     - Send `Ctrl+F2` keystrokes
   - **Method C:** Try timing tricks
     - Power on NAS
     - Wait 1-2 seconds (let USB initialize)
     - Rapidly press `Ctrl+F2` or `F2` repeatedly

2. **In BIOS:**
   - Navigate to: `Advanced → Watchdog`
   - Set to: `Disabled`
   - Save: Press `F10`
   - Reboot

3. **Install TrueNAS:**
   - Boot from USB installer
   - Install to NVMe drive
   - No more watchdog reboots!

**Pros:**
- ✅ Permanent fix
- ✅ No OS-level workarounds needed
- ✅ Cleanest solution

**Cons:**
- ❌ Requires BIOS access (difficult with KVM)
- ❌ May need direct keyboard connection

---

### Option 2: Disable Watchdog via IPMI (No BIOS Needed!)

**Best if:** BIOS access fails, TrueNAS is already installed

**Steps:**
1. **Boot TrueNAS installer** (with watchdog disable parameters in GRUB - see Option 3)
2. **Complete installation quickly** (before watchdog triggers)
3. **Once TrueNAS is running:**
   ```bash
   # SSH into TrueNAS
   ssh root@<truenas-ip>
   
   # Install ipmitool (if not already installed)
   # TrueNAS SCALE:
   apt-get update && apt-get install -y ipmitool
   
   # Disable watchdog
   ipmitool mc watchdog off
   
   # Verify it's disabled
   ipmitool mc watchdog get
   ```

4. **Make it permanent** (add to startup):
   - **TrueNAS SCALE:** Add to Post-Init script:
     ```bash
     ipmitool mc watchdog off
     ```
   - **TrueNAS CORE:** Add to `/etc/rc.local`

**Pros:**
- ✅ No BIOS access needed
- ✅ Works from OS level
- ✅ Can be automated

**Cons:**
- ❌ Requires getting TrueNAS installed first (may reboot during install)
- ❌ Watchdog may re-enable on reboot (need startup script)

---

### Option 3: Boot with Watchdog Disable Parameters (Temporary)

**Best if:** You can access GRUB, want to install TrueNAS

**Steps:**
1. **Boot to GRUB** (you've done this before!)
2. **Edit boot entry** (press `e` when GRUB menu appears)
3. **Find line starting with `linux`**
4. **Add to end of line:**
   ```
   nmi_watchdog=0 modprobe.blacklist=iTCO_wdt
   ```
5. **Press `Ctrl+x`** to boot
6. **TrueNAS installer should load without watchdog reboots**
7. **Complete installation quickly**
8. **After install, use Option 2** to disable watchdog permanently

**Example GRUB boot command:**
```grub
linux /vmlinuz boot=live components quiet nmi_watchdog=0 modprobe.blacklist=iTCO_wdt
initrd /initrd.img
boot
```

**Pros:**
- ✅ Works immediately
- ✅ No BIOS access needed
- ✅ Can complete installation

**Cons:**
- ❌ Temporary (only for this boot)
- ❌ Need to disable permanently after install (Option 2)

---

### Option 4: Fast Installation Before Watchdog Triggers

**Best if:** Watchdog takes 2-3 minutes to trigger, you can install quickly

**Steps:**
1. **Boot TrueNAS installer**
2. **Work FAST** - complete installation before watchdog reboots
3. **After install, use Option 2** to disable watchdog

**Pros:**
- ✅ Simplest approach
- ✅ No BIOS or GRUB editing needed

**Cons:**
- ❌ Risky - may reboot mid-installation
- ❌ Watchdog timing is unpredictable
- ❌ May need multiple attempts

---

## 📋 Recommended Approach

### Strategy: Combine Options 3 + 2

**Phase 1: Install TrueNAS (Option 3)**
1. Boot to GRUB
2. Add watchdog disable parameters to boot command
3. Complete TrueNAS installation
4. Install to NVMe drive

**Phase 2: Disable Watchdog Permanently (Option 2)**
1. SSH into TrueNAS after installation
2. Install `ipmitool`
3. Disable watchdog: `ipmitool mc watchdog off`
4. Add to startup script (permanent)

**Why this works:**
- ✅ No BIOS access needed
- ✅ GRUB is accessible (you've done this before)
- ✅ Permanent fix after installation
- ✅ Most reliable approach

---

## 🔧 Additional Considerations

### USB Port Selection

**Important:** Use USB 2.0 port for installer!
- USB 3.0 ports may cause boot failures
- USB 2.0 is more compatible with TrueNAS installer
- Check which ports are USB 2.0 vs 3.0

### Boot Order

**After installation:**
- Set boot order: NVMe → eMMC
- This boots TrueNAS from NVMe
- UGOS remains on eMMC for rollback

### Data Migration

**Your SATA drives have BTRFS data:**
- TrueNAS can import BTRFS (read-only)
- Better to create new ZFS pool
- Migrate data from BTRFS to ZFS
- Or keep SATA drives as separate storage

---

## ✅ Quick Decision Tree

**Can you access BIOS?**
- **Yes** → Use Option 1 (disable watchdog in BIOS)
- **No** → Continue below

**Can you access GRUB?**
- **Yes** → Use Option 3 (add watchdog disable to GRUB boot)
- **No** → Try Option 4 (fast installation) or get BIOS access

**After TrueNAS is installed:**
- **Always** → Use Option 2 (disable watchdog via IPMI permanently)

---

## 🎯 Next Steps

**Recommended immediate action:**

1. **Try accessing BIOS** with direct USB keyboard (Option 1, Method A)
   - If successful: disable watchdog, then install TrueNAS
   - If fails: proceed to Option 3

2. **If BIOS access fails:**
   - Boot to GRUB
   - Add watchdog disable parameters (Option 3)
   - Complete TrueNAS installation
   - Then disable watchdog permanently via IPMI (Option 2)

**Which option do you want to try first?**

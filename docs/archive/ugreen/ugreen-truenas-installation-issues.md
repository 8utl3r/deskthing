# TrueNAS Scale Installation on Ugreen DXP2800 - Known Issues & Solutions

## ✅ Confirmation: TrueNAS Scale Works on DXP2800

**Multiple successful installations documented:**
- ✅ TrueNAS Scale 25.04RC1 installed on eMMC
- ✅ TrueNAS Scale installed on NVMe drives
- ✅ Community forum has active DXP2800 + TrueNAS discussions
- ✅ Hardware is compatible (Intel N100, I226-V network)

**Sources:**
- TrueNAS Community Forums (multiple successful installs)
- Installation guides specifically for Ugreen DXP2800
- YouTube videos showing successful installations

## ⚠️ Critical Issue: USB Port Compatibility

### Problem
**USB 3.0 ports don't work with TrueNAS installer!**

**Symptoms:**
- Bootloader loads (GRUB appears)
- Kernel starts loading
- Fails during OS handover
- "Cannot remount root" errors
- "Failed to boot correctly" errors

**Root Cause:**
- TrueNAS installer lacks drivers for USB 3.0 ports on DXP2800
- Bootloader works, but OS can't access USB 3.0 during installation

### Solution: Use USB 2.0 Port

**Critical Steps:**
1. **Identify USB 2.0 port** on DXP2800
   - Usually marked or different color
   - May need to check manual/specs
   - Often USB-A ports (not USB-C)

2. **Move USB drive to USB 2.0 port**
   - Unplug from USB 3.0
   - Plug into USB 2.0 port
   - KVM/keyboard may need to move too

3. **Reboot and boot from USB 2.0**
   - Should boot successfully
   - Installer should load properly

## 🔧 Other Known Issues & Solutions

### Issue 1: Watchdog Timer Not Disabled

**Symptom:** TrueNAS reboots continuously after installation

**Solution:** Must disable in BIOS before installation
- `Advanced → Watchdog → Disabled`

### Issue 2: eMMC Boot Conflicts

**Symptom:** Boot fails or boots wrong OS

**Solution:** Disable eMMC in BIOS (if installing on NVMe)
- `Advanced → Storage → eMMC → Disabled`
- Or set boot order: NVMe → eMMC

### Issue 3: GRUB Installation Failures

**Symptom:** GRUB fails to install during TrueNAS setup

**Solution:** Wipe target drive completely first
```bash
# From TrueNAS installer shell
dd if=/dev/zero of=/dev/nvme0n1 bs=1M count=100
```

### Issue 4: Boot from GRUB Instead of BIOS

**Current Situation:** You're booting from GRUB (UGOS's bootloader)

**Better Approach:** Boot directly from BIOS/UEFI boot menu
- Access BIOS (F2/Delete during boot)
- Use "Boot Override" or "Boot Menu"
- Select USB directly
- Bypasses GRUB entirely

## 🎯 Recommended Installation Method

### Method 1: Boot from BIOS (Recommended)

**Steps:**
1. **Access BIOS** via KVM (F2/Delete during boot)
2. **Disable Watchdog Timer** (Critical!)
3. **Use Boot Override** to select USB
4. **Boot directly from USB** (bypasses GRUB)
5. **TrueNAS installer loads**

**Advantages:**
- Bypasses GRUB boot issues
- Direct boot from USB
- Cleaner installation process

### Method 2: Fix GRUB Boot (Current Approach)

**If you want to continue from GRUB:**

**Try adding boot parameters:**
```grub
set root=(hd0)
linux /vmlinuz boot=live components quiet
initrd /initrd.img
boot
```

**Or try:**
```grub
set root=(hd0)
linux /vmlinuz fromiso=/dev/sdb1 boot=live
initrd /initrd.img
boot
```

**But first:** Make sure USB is in USB 2.0 port!

## 🔍 Troubleshooting Your Current Issue

### Check 1: USB Port Type

**Question:** Is your USB drive plugged into USB 2.0 or USB 3.0 port?

**How to tell:**
- USB 2.0: Usually black or white inside
- USB 3.0: Usually blue inside
- Check DXP2800 manual for port locations

**Action:** Move USB to USB 2.0 port if it's in USB 3.0

### Check 2: Boot Parameters

**Try adding boot parameters:**
```grub
set root=(hd0)
linux /vmlinuz boot=live
initrd /initrd.img
boot
```

### Check 3: Try Different Boot Method

**Instead of GRUB, boot from BIOS:**
1. Reboot
2. Access BIOS (F2/Delete)
3. Use Boot Menu/Boot Override
4. Select USB directly
5. Bypass GRUB entirely

## 📋 Pre-Installation Checklist

Before trying again:

- [ ] **USB drive in USB 2.0 port** (not USB 3.0) ⚠️ CRITICAL
- [ ] **Watchdog timer disabled** in BIOS
- [ ] **Boot order set** (USB → NVMe → eMMC)
- [ ] **NVMe drive installed** and detected
- [ ] **USB drive verified** (bootable TrueNAS ISO)

## 🚀 Alternative: Boot from BIOS Instead of GRUB

**Since GRUB boot is failing, try BIOS boot:**

1. **Reboot NAS**
2. **Access BIOS** (F2/Delete when logo appears)
3. **Look for "Boot Menu" or "Boot Override"**
4. **Select USB drive**
5. **Boot directly** (bypasses GRUB)

**This is often more reliable than GRUB chainloading!**

---

## ✅ Conclusion

**TrueNAS Scale CAN be installed on DXP2800** - it's confirmed working.

**Most likely issue:** USB 3.0 port incompatibility

**Next step:** Move USB to USB 2.0 port and try booting from BIOS boot menu instead of GRUB.

**What port is your USB currently in?** USB 2.0 or USB 3.0?

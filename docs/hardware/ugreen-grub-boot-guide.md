# Booting TrueNAS from GRUB on Ugreen DXP2800

**Great news!** You can access GRUB bootloader. This gives us options!

## 🎯 What You Can Do from GRUB

### Option 1: Boot USB Directly from GRUB (Easiest!)

**If GRUB shows boot options:**
1. Look for your USB drive in the GRUB menu
2. Select it and press Enter
3. TrueNAS installer should boot!

**If USB not shown:**
- Press `c` to enter GRUB command line
- We can manually boot from USB

### Option 2: Chainload USB Bootloader

From GRUB command line, we can chainload to USB's bootloader.

### Option 3: Access BIOS from GRUB

Some systems allow accessing BIOS from GRUB menu.

---

## 📋 GRUB Commands for USB Boot

### Method 1: List Available Devices

**In GRUB command line (press `c`):**
```grub
ls
```
This shows all available devices/partitions.

**Look for:**
- `(hd0)` - First hard disk (usually eMMC)
- `(hd1)` - Second disk (might be USB or NVMe)
- `(hd2)` - Third disk (might be USB)
- `(hd0,msdos1)` - First partition on first disk
- `(hd1,msdos1)` - First partition on second disk (might be USB)

### Method 2: Check USB Device

**List partitions on each device:**
```grub
ls (hd0)/
ls (hd1)/
ls (hd2)/
```

**Look for USB** - it will show partitions like:
- `(hd1,msdos1)` - USB boot partition
- `(hd1,msdos2)` - USB data partition

### Method 3: Boot from USB

**Once you identify USB (let's say it's hd1):**
```grub
set root=(hd1,msdos1)
chainloader +1
boot
```

**Or if USB is hd2:**
```grub
set root=(hd2,msdos1)
chainloader +1
boot
```

---

## 🔍 Step-by-Step: Boot TrueNAS USB from GRUB

### Step 1: Enter GRUB Command Line

1. **At GRUB prompt**, press **`c`** to enter command line
2. You should see: `grub>`

### Step 2: Find USB Device

**List devices:**
```grub
ls
```

**Check each device for USB:**
```grub
ls (hd0)/
ls (hd1)/
ls (hd2)/
ls (hd3)/
```

**Look for**:
- Device with `msdos1` partition (USB boot partition)
- Usually `(hd1)` or `(hd2)` if eMMC is `(hd0)`

### Step 3: Boot from USB

**Once you find USB (example: hd1):**
```grub
set root=(hd1,msdos1)
chainloader +1
boot
```

**This will:**
- Set USB as root device
- Chainload USB's bootloader
- Boot TrueNAS installer

---

## 🎯 Quick Reference Commands

**In GRUB command line (`c`):**

```grub
# List all devices
ls

# Check device 0 (usually eMMC)
ls (hd0)/

# Check device 1 (might be USB or NVMe)
ls (hd1)/

# Check device 2 (might be USB)
ls (hd2)/

# Boot from USB (if USB is hd1)
set root=(hd1,msdos1)
chainloader +1
boot

# Boot from USB (if USB is hd2)
set root=(hd2,msdos1)
chainloader +1
boot
```

---

## 🔄 Alternative: Access BIOS from GRUB

**Some GRUB menus have BIOS option:**
- Look for "BIOS Setup" or "Enter Setup" in GRUB menu
- Select it to enter BIOS
- Then configure settings normally

---

## ✅ What to Do Right Now

**At GRUB prompt, try:**

1. **Press `c`** to enter command line
2. **Type**: `ls` and press Enter
3. **Share the output** - I'll help identify which device is USB
4. **Then we'll boot from USB** directly!

**Or if GRUB shows a menu:**
- Look for USB device in the list
- Select it and boot

---

## ⚠️ CRITICAL: Disable Watchdog Timer (Prevents Reboots!)

**The Ugreen DXP2800 has a watchdog timer that causes reboots!**

**Problem:** Watchdog expects UGOS heartbeat. When TrueNAS runs, no heartbeat → **automatic reboot every few minutes**.

**Solution:** Add watchdog disable parameters to GRUB boot.

### Method 1: Edit GRUB Boot Entry (Recommended)

**When GRUB menu appears:**

1. **Highlight** the TrueNAS boot entry
2. **Press `e`** to edit boot parameters
3. **Find the line** starting with `linux` or `linuxefi`
4. **Move cursor** to end of that line
5. **Add these parameters:**
   ```
   nmi_watchdog=0 modprobe.blacklist=iTCO_wdt
   ```
6. **Press `Ctrl+x`** or **`F10`** to boot

**Example (before edit):**
```
linux /vmlinuz boot=live components quiet
```

**Example (after edit):**
```
linux /vmlinuz boot=live components quiet nmi_watchdog=0 modprobe.blacklist=iTCO_wdt
```

### Method 2: GRUB Command Line

**If booting from GRUB command line, add parameters:**

```grub
set root=(hd1,msdos1)
linux /vmlinuz boot=live components quiet nmi_watchdog=0 modprobe.blacklist=iTCO_wdt
initrd /initrd.img
boot
```

**These parameters:**
- `nmi_watchdog=0` - Disables NMI watchdog
- `modprobe.blacklist=iTCO_wdt` - Prevents Intel watchdog driver from loading

**This prevents watchdog reboots during TrueNAS installation!**

---

## 🚨 Troubleshooting

### Watchdog Timer Causing Reboots

**Symptoms:**
- System reboots every few minutes
- Happens during TrueNAS installation
- Happens when UGOS isn't running

**Solution:**
- Add watchdog disable parameters (see above)
- Or disable watchdog in BIOS (permanent fix)

**To disable in BIOS:**
- Reboot, press `Ctrl+F2` immediately
- Navigate to: `Advanced → Watchdog`
- Set to: `Disabled`
- Save (`F10`)

### USB Not Found in GRUB

**Solutions:**
- Make sure USB is inserted
- Try different USB port (USB 2.0 recommended)
- In GRUB: `ls` to see all devices
- USB might be `(hd1)`, `(hd2)`, or `(hd3)`

### Chainloader Fails

**Try:**
```grub
set root=(hdX,msdos1)
linux /boot/vmlinuz nmi_watchdog=0 modprobe.blacklist=iTCO_wdt
initrd /boot/initrd
boot
```

**Or:**
```grub
set root=(hdX,msdos1)
multiboot /boot/grub/i386-pc/core.img
boot
```

### Still Need BIOS Access

**From GRUB:**
- Some systems: Press `e` to edit, then add BIOS entry
- Or reboot and try F2/Delete again
- KVM should show BIOS screen

---

**What do you see at the GRUB prompt?** Share the output of `ls` and I'll help you boot from USB!

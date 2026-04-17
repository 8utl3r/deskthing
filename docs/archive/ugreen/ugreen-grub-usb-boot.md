# Booting TrueNAS USB from GRUB - Troubleshooting

## Issue: Unknown File System Error

**Problem**: Seeing `msdos2` but getting "unknown file system" error.

**Likely cause**: TrueNAS ISO uses **GPT** partition scheme, not MBR (msdos).

## Solution: Look for GPT Partitions

### Step 1: List All Devices

```grub
ls
```

### Step 2: Check for GPT Partitions

**Try these instead of msdos:**
```grub
ls (hd0,gpt1)/
ls (hd0,gpt2)/
ls (hd1,gpt1)/
ls (hd1,gpt2)/
ls (hd2,gpt1)/
ls (hd2,gpt2)/
```

**Or check for EFI partition:**
```grub
ls (hd0,efi)/
ls (hd1,efi)/
ls (hd2,efi)/
```

### Step 3: Boot from GPT Partition

**Once you find the USB (example: hd1 with gpt1):**
```grub
set root=(hd1,gpt1)
chainloader +1
boot
```

**Or try EFI boot:**
```grub
set root=(hd1,efi)
chainloader /EFI/BOOT/bootx64.efi
boot
```

## Alternative: Try Different Partition Numbers

**If you see msdos2, try msdos1:**
```grub
ls (hd0,msdos1)/
ls (hd1,msdos1)/
```

**The boot partition is usually partition 1, not 2.**

## Method 2: Direct EFI Boot

**If USB has EFI bootloader:**
```grub
set root=(hd1,gpt1)
chainloader /EFI/BOOT/BOOTX64.EFI
boot
```

## Method 3: Try All Devices

**Systematic approach - try each device:**

```grub
# Try device 0
set root=(hd0,gpt1)
chainloader +1
boot

# If that doesn't work, try device 1
set root=(hd1,gpt1)
chainloader +1
boot

# Or device 2
set root=(hd2,gpt1)
chainloader +1
boot
```

## What to Look For

**When you `ls` a partition, you should see:**
- `/EFI/` directory (for EFI boot)
- `/boot/` directory
- Files like `bootx64.efi` or `grub.cfg`

**If you see these, that's the boot partition!**

## Quick Test Commands

**At GRUB prompt, try these in order:**

```grub
# 1. List devices
ls

# 2. Check device 0 with GPT
ls (hd0,gpt1)/

# 3. Check device 1 with GPT  
ls (hd1,gpt1)/

# 4. Check device 2 with GPT
ls (hd2,gpt1)/

# 5. If you find one that works, boot it:
set root=(hdX,gpt1)
chainloader +1
boot
```

---

**Try `ls (hd0,gpt1)/` or `ls (hd1,gpt1)/` and see what you get!**

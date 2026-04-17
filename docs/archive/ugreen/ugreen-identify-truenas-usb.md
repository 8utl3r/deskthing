# Identifying TrueNAS USB Drive in GRUB

## 🔍 Files That Identify TrueNAS ISO

### Method 1: Check for TrueNAS-Specific Files

**TrueNAS Scale ISO contains these unique files:**

```grub
# Check for TrueNAS version/release file
ls (hdX,gpt1)/version
ls (hdX,gpt1)/.truenas_version

# Check for TrueNAS boot files
ls (hdX,gpt1)/boot/grub/grub.cfg
ls (hdX,gpt1)/boot/kernel*

# Check EFI directory (TrueNAS has specific EFI structure)
ls (hdX,gpt1)/EFI/BOOT/
ls (hdX,gpt1)/EFI/BOOT/BOOTX64.EFI

# Check for installer files
ls (hdX,gpt1)/installer/
ls (hdX,gpt1)/*.manifest
```

### Method 2: Check File Contents

**If you can read files, check for TrueNAS identifiers:**

```grub
# Try to read version file (if it exists)
cat (hdX,gpt1)/version

# Check grub config for TrueNAS references
cat (hdX,gpt1)/boot/grub/grub.cfg | grep -i truenas
```

### Method 3: Look for ISO9660 Filesystem

**TrueNAS ISO uses ISO9660 filesystem:**

```grub
# Check if partition shows ISO9660 structure
ls (hdX,gpt1)/

# Should see directories like:
# - EFI/
# - boot/
# - installer/
# - syslinux/ (sometimes)
```

## 🎯 Quick Identification Test

**At GRUB prompt, try this for each device:**

```grub
# Test device 0
ls (hd0,gpt1)/EFI/BOOT/
# If you see BOOTX64.EFI or similar → Likely TrueNAS USB

# Test device 1  
ls (hd1,gpt1)/EFI/BOOT/
# If you see BOOTX64.EFI → This is TrueNAS USB!

# Test device 2
ls (hd2,gpt1)/EFI/BOOT/
```

**TrueNAS USB will have:**
- `/EFI/BOOT/BOOTX64.EFI` file
- `/boot/` directory with kernel files
- `/installer/` directory (TrueNAS installer)

## 📋 Step-by-Step Identification

### Step 1: List All Devices
```grub
ls
```
Note which devices show `gpt` partitions.

### Step 2: Check Each Device for TrueNAS Files

**For each device with gpt1 partition:**

```grub
# Check for EFI boot directory
ls (hd0,gpt1)/EFI/BOOT/

# If you see files like BOOTX64.EFI, that's TrueNAS!
```

### Step 3: Verify It's TrueNAS

**Look for these indicators:**
- ✅ `/EFI/BOOT/BOOTX64.EFI` exists
- ✅ `/boot/` directory exists
- ✅ `/installer/` directory exists (TrueNAS specific)
- ✅ File system shows ISO9660 structure

## 🚀 Once Identified, Boot It

**If device is (hd1,gpt1) and shows TrueNAS files:**

```grub
set root=(hd1,gpt1)
chainloader /EFI/BOOT/BOOTX64.EFI
boot
```

**Or simpler:**
```grub
set root=(hd1,gpt1)
chainloader +1
boot
```

---

## 🔍 What to Look For

**TrueNAS USB will show:**
```
(hd1,gpt1): Files found
  EFI/
  boot/
  installer/
  syslinux/
  [other ISO files]
```

**Regular hard drive will show:**
```
(hd0,msdos2): Files found
  [regular Linux/UGOS files]
  [no EFI/BOOT/BOOTX64.EFI]
```

---

**Try `ls (hd0,gpt1)/EFI/BOOT/` and `ls (hd1,gpt1)/EFI/BOOT/` - whichever shows `BOOTX64.EFI` is your TrueNAS USB!**

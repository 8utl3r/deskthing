# Fixing "Unknown Filesystem" Error in GRUB

**Issue**: `linux /boot/vmlinuz` gives "unknown filesystem"

**Cause**: GRUB can't read the filesystem on that partition. Need to find the correct partition.

## 🔍 Step 1: Check All Partitions on hd0

**List all partitions:**
```grub
ls (hd0)/
```

**This shows all partitions like:**
- `(hd0,1)` or `(hd0,gpt1)`
- `(hd0,2)` or `(hd0,gpt2)`
- `(hd0,msdos1)`
- etc.

## 🔍 Step 2: Try Different Partition Numbers

**Try each partition:**

```grub
# Try partition 1
ls (hd0,1)/boot/

# Try partition 2
ls (hd0,2)/boot/

# Try gpt2 instead of gpt1
ls (hd0,gpt2)/boot/

# Try msdos1
ls (hd0,msdos1)/boot/
```

## 🔍 Step 3: Check Root Directory of Each Partition

**Check what's actually readable:**

```grub
# Check partition 1
ls (hd0,1)/

# Check partition 2
ls (hd0,2)/

# Check gpt1
ls (hd0,gpt1)/

# Check gpt2
ls (hd0,gpt2)/
```

**Look for partitions that show:**
- `/EFI/` directory
- `/boot/` directory
- Files you can actually see

## 🚀 Step 4: Alternative Boot Methods

### Method 1: Try Different Partition

**If gpt1 doesn't work, try:**
```grub
set root=(hd0,gpt2)
linux /boot/vmlinuz
initrd /boot/initrd.img
boot
```

### Method 2: Try Without Partition Number

**Some GRUB versions:**
```grub
set root=hd0
linux /boot/vmlinuz
initrd /boot/initrd.img
boot
```

### Method 3: Check EFI Partition

**TrueNAS ISO might have separate EFI partition:**
```grub
# Check if there's an EFI partition
ls (hd0,efi)/

# If EFI partition exists, kernel might be in root
ls (hd0,gpt2)/
```

## 📋 Systematic Approach

**Try these in order:**

1. **List all partitions:**
   ```grub
   ls (hd0)/
   ```

2. **Check each partition:**
   ```grub
   ls (hd0,1)/
   ls (hd0,2)/
   ls (hd0,gpt1)/
   ls (hd0,gpt2)/
   ```

3. **Find one that shows files** (not "unknown filesystem")

4. **Use that partition for boot:**
   ```grub
   set root=(hd0,X)  # X = partition that worked
   linux /boot/vmlinuz
   initrd /boot/initrd.img
   boot
   ```

---

**First, run `ls (hd0)/` and share what partitions you see!**

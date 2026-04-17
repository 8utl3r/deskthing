# Boot TrueNAS by Loading Kernel Directly

**Issue**: GRUB says "need to load the kernel first"

**Solution**: Load kernel and initrd directly instead of chainloading.

## 🔍 Step 1: Find Kernel Files

**At GRUB prompt, check for kernel files:**

```grub
# Check for kernel in boot directory
ls (hd0,gpt1)/boot/

# Look for files like:
# - vmlinuz
# - kernel
# - bzImage
# - initrd.img
# - initramfs
```

## 🚀 Step 2: Load Kernel and Initrd

**Once you find the kernel files, boot with:**

```grub
set root=(hd0,gpt1)
linux /boot/vmlinuz
initrd /boot/initrd.img
boot
```

**Or if files are named differently:**

```grub
set root=(hd0,gpt1)
linux /boot/kernel
initrd /boot/initramfs
boot
```

## 📋 Common TrueNAS Kernel Paths

**Try these paths:**

```grub
# Path 1 (most common)
set root=(hd0,gpt1)
linux /boot/vmlinuz
initrd /boot/initrd.img
boot

# Path 2
set root=(hd0,gpt1)
linux /boot/kernel
initrd /boot/initrd
boot

# Path 3 (if in root)
set root=(hd0,gpt1)
linux /vmlinuz
initrd /initrd.img
boot
```

## 🔍 Step-by-Step Discovery

**First, let's find the kernel:**

```grub
# List boot directory contents
ls (hd0,gpt1)/boot/

# Look for files ending in:
# - vmlinuz*
# - kernel*
# - bzImage*
# - initrd*
# - initramfs*
```

**Share what you see in `/boot/` and I'll give you the exact commands!**

## Alternative: Check ISO Structure

**TrueNAS ISO might have kernel in different location:**

```grub
# Check root directory
ls (hd0,gpt1)/

# Check for syslinux directory
ls (hd0,gpt1)/syslinux/

# Check for isolinux directory  
ls (hd0,gpt1)/isolinux/
```

---

**Try `ls (hd0,gpt1)/boot/` first and share what files you see!**

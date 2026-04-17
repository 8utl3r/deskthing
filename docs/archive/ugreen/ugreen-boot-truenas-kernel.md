# Boot TrueNAS with Kernel - vmlinuz Found!

**Kernel found**: `vmlinuz` in `/boot/`

## 🔍 Step 1: Find Initrd File

**Check for initrd/initramfs file:**

```grub
ls (hd0,gpt1)/boot/
```

**Look for:**
- `initrd.img`
- `initrd`
- `initramfs.img`
- `initramfs`
- Files starting with `initrd` or `initramfs`

## 🚀 Step 2: Boot Commands

**Once you find the initrd file, use these commands:**

**If you see `initrd.img`:**
```grub
set root=(hd0,gpt1)
linux /boot/vmlinuz
initrd /boot/initrd.img
boot
```

**If you see `initrd` (no .img):**
```grub
set root=(hd0,gpt1)
linux /boot/vmlinuz
initrd /boot/initrd
boot
```

**If you see `initramfs.img`:**
```grub
set root=(hd0,gpt1)
linux /boot/vmlinuz
initrd /boot/initramfs.img
boot
```

## 📋 Complete Boot Sequence

**Type these commands one at a time:**

```grub
set root=(hd0,gpt1)
```
*Press Enter*

```grub
linux /boot/vmlinuz
```
*Press Enter*

```grub
initrd /boot/initrd.img
```
*Press Enter* (use actual initrd filename you see)

```grub
boot
```
*Press Enter*

## 🔍 If Initrd Not in /boot/

**Check root directory:**
```grub
ls (hd0,gpt1)/
```

**Or check syslinux/isolinux:**
```grub
ls (hd0,gpt1)/syslinux/
ls (hd0,gpt1)/isolinux/
```

---

**First, run `ls (hd0,gpt1)/boot/` and tell me what initrd/initramfs file you see!**

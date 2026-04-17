# Boot TrueNAS - Correct Commands

**Files found in root of (hd0)/:**
- ✅ `vmlinuz` (kernel)
- ✅ `initrd.img` (initrd)
- ✅ `TrueNAS-SCALE.update` (confirms TrueNAS!)
- ✅ `EFI/` directory

**Files are in root, not `/boot/` subdirectory!**

## 🚀 Boot Commands

**At GRUB prompt, type these commands:**

```grub
set root=(hd0)
linux /vmlinuz
initrd /initrd.img
boot
```

**Type each command and press Enter after each.**

## 📋 Step-by-Step

1. **Set root device:**
   ```grub
   set root=(hd0)
   ```
   *Press Enter*

2. **Load kernel:**
   ```grub
   linux /vmlinuz
   ```
   *Press Enter*

3. **Load initrd:**
   ```grub
   initrd /initrd.img
   ```
   *Press Enter*

4. **Boot:**
   ```grub
   boot
   ```
   *Press Enter*

## ✅ Expected Result

After `boot`:
- TrueNAS boot process starts
- You'll see TrueNAS loading screen
- TrueNAS installer menu appears
- Can proceed with installation!

---

**Ready? Type these commands:**

```grub
set root=(hd0)
linux /vmlinuz
initrd /initrd.img
boot
```

Let me know when TrueNAS installer loads!

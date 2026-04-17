# TrueNAS Scale GRUB Boot Parameters

**Issue**: Boot fails after loading kernel/initrd

**Solution**: May need specific boot parameters for TrueNAS installer

## 🔍 Common TrueNAS Boot Parameters

### Standard Boot Parameters

```grub
set root=(hd0)
linux /vmlinuz boot=live components quiet
initrd /initrd.img
boot
```

### Alternative Parameters

**If standard doesn't work:**

```grub
set root=(hd0)
linux /vmlinuz boot=live fromiso=/dev/sdb1
initrd /initrd.img
boot
```

**Or:**

```grub
set root=(hd0)
linux /vmlinuz boot=live union=overlay
initrd /initrd.img
boot
```

**Or with explicit device:**

```grub
set root=(hd0)
linux /vmlinuz boot=live fromiso=/dev/disk/by-label/TrueNAS-SCALE-25.04.2.4
initrd /initrd.img
boot
```

## 🔧 Troubleshooting Specific Errors

### Error: "Cannot mount root"

**Try:**
```grub
set root=(hd0)
linux /vmlinuz boot=live fromiso=/dev/sdb1
initrd /initrd.img
boot
```

### Error: "USB not found" or "Cannot access installation media"

**Try:**
```grub
set root=(hd0)
linux /vmlinuz boot=live components quiet
initrd /initrd.img
boot
```

### Error: Kernel panic or system hangs

**Try:**
```grub
set root=(hd0)
linux /vmlinuz boot=live components quiet nomodeset
initrd /initrd.img
boot
```

## 📋 Complete Boot Sequence to Try

**At GRUB prompt (`grub>`), try these in order:**

**Attempt 1:**
```grub
set root=(hd0)
linux /vmlinuz boot=live components quiet
initrd /initrd.img
boot
```

**Attempt 2 (if 1 fails):**
```grub
set root=(hd0)
linux /vmlinuz boot=live fromiso=/dev/sdb1
initrd /initrd.img
boot
```

**Attempt 3 (if 2 fails):**
```grub
set root=(hd0)
linux /vmlinuz boot=live union=overlay
initrd /initrd.img
boot
```

**Attempt 4 (if 3 fails):**
```grub
set root=(hd0)
linux /vmlinuz boot=live components quiet nomodeset
initrd /initrd.img
boot
```

---

**What exact error message did you see when it "failed to boot correctly"?**

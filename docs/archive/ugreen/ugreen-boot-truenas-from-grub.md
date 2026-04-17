# Boot TrueNAS from GRUB - hd0 Confirmed

**USB Device**: hd0 (TrueNAS USB confirmed)

## 🚀 Boot Commands

### Method 1: Standard Chainloader (Try This First)

**At GRUB prompt:**
```grub
set root=(hd0,gpt1)
chainloader +1
boot
```

### Method 2: EFI Bootloader (If Method 1 Doesn't Work)

```grub
set root=(hd0,gpt1)
chainloader /EFI/BOOT/BOOTX64.EFI
boot
```

### Method 3: Alternative EFI Path

```grub
set root=(hd0,gpt1)
chainloader /EFI/BOOT/bootx64.efi
boot
```

### Method 4: If Using msdos Partition Scheme

**If gpt1 doesn't work, try:**
```grub
set root=(hd0,msdos1)
chainloader +1
boot
```

## 📋 Step-by-Step

1. **At GRUB prompt**, type:
   ```grub
   set root=(hd0,gpt1)
   ```

2. **Press Enter**

3. **Type:**
   ```grub
   chainloader +1
   ```

4. **Press Enter**

5. **Type:**
   ```grub
   boot
   ```

6. **Press Enter**

7. **TrueNAS installer should start loading!**

## ✅ Expected Result

After `boot` command:
- Screen should show TrueNAS boot process
- You'll see TrueNAS logo/loading screen
- TrueNAS installer menu should appear
- Can proceed with installation

## 🚨 If It Doesn't Boot

**Try these alternatives:**

```grub
# Try gpt2 instead of gpt1
set root=(hd0,gpt2)
chainloader +1
boot

# Or try msdos1
set root=(hd0,msdos1)
chainloader +1
boot

# Or direct EFI path
set root=(hd0,gpt1)
chainloader /EFI/BOOT/BOOTX64.EFI
boot
```

---

**Ready? Type these commands in GRUB:**

```grub
set root=(hd0,gpt1)
chainloader +1
boot
```

Let me know what happens!

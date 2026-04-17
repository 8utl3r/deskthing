# Accessing BIOS Before GRUB on Ugreen DXP2800

**Problem**: F2 and Delete go to GRUB menu, not BIOS

**Cause**: GRUB is loading very early and intercepting BIOS keys

## 🔍 Solution: Access BIOS Before GRUB

### Method 1: Try Different Keys Earlier

**Timing is critical - press keys BEFORE Ugreen logo:**

1. **Power on NAS**
2. **Immediately start pressing** (before any logo appears):
   - **`F12`** (Boot Menu - often works even with GRUB)
   - **`Esc`** (sometimes bypasses GRUB)
   - **`Ctrl+F12`** (Ugreen-specific)
   - **`Ctrl+Alt+Esc`**
   - **`F1`** (sometimes BIOS)
   - **`F10`** (sometimes BIOS)

### Method 2: Interrupt GRUB Boot Process

**When GRUB menu appears:**
- **Press `Esc`** quickly (might cancel GRUB and show BIOS)
- **Or wait for timeout** - some systems show BIOS option if you wait

### Method 3: Use GRUB to Access BIOS

**Some GRUB menus have BIOS option:**
- Look for "BIOS Setup" or "Enter Setup" in GRUB menu
- May be hidden - try arrow keys to navigate

### Method 4: Boot from GRUB Command Line

**Since BIOS access is difficult, boot TrueNAS from GRUB:**

**At GRUB prompt (`grub>`), try:**

```grub
# Set USB as root
set root=(hd0)

# Load kernel with boot parameters
linux /vmlinuz boot=live components quiet

# Load initrd
initrd /initrd.img

# Boot
boot
```

**Or try with different boot parameters:**
```grub
set root=(hd0)
linux /vmlinuz fromiso=/dev/sdb1 boot=live
initrd /initrd.img
boot
```

## 🎯 Recommended: Boot from GRUB Command Line

**Since BIOS is hard to access, let's boot TrueNAS from GRUB:**

1. **At GRUB menu**, press **`c`** for command line
2. **Type these commands:**

```grub
set root=(hd0)
linux /vmlinuz boot=live
initrd /initrd.img
boot
```

**The `boot=live` parameter tells it to boot as live installer.**

---

## 🔧 Alternative: Edit GRUB Entry

**At GRUB menu:**
1. **Press `e`** to edit the UGOSPRO-NAS entry
2. **Modify boot commands** to point to USB
3. **Press Ctrl+X** to boot

**But this is more complex - command line is easier.**

---

**Try booting from GRUB command line with `boot=live` parameter!**

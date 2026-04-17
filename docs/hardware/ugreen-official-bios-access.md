# Official Ugreen DXP2800 BIOS Access Method

**Source**: Debian Wiki, Ugreen Community Forums, Technical Documentation

## ✅ Official BIOS Access Keys

### Primary Method: Ctrl + F12

**For Boot Menu (Select Boot Device):**
- Press and hold **`Ctrl + F12`** during boot
- Or rapidly tap **`Ctrl + F12`** repeatedly
- This shows boot device selection menu

**For BIOS/UEFI Setup:**
- Press and hold **`Ctrl + F2`** during boot
- Or rapidly tap **`Ctrl + F2`** repeatedly
- This enters full BIOS setup

### Alternative: SSH Method (If UGOS is Running)

**From SSH, reboot directly into BIOS:**
```bash
ssh pete@192.168.0.158
sudo systemctl reboot --firmware-setup
```

**This command:**
- Reboots the NAS
- Automatically enters BIOS/UEFI setup
- Bypasses GRUB entirely
- No need to press keys!

## 📋 Step-by-Step: Access BIOS

### Method 1: Keyboard Combination (Recommended)

1. **Power on NAS** (or reboot)
2. **Immediately press and hold**: **`Ctrl + F12`**
   - Hold both keys together
   - Or rapidly tap repeatedly
   - Start pressing BEFORE any logo appears
3. **Boot Menu should appear**
   - Select USB drive from list
   - Or press another key to enter full BIOS

**For Full BIOS Setup:**
- Press **`Ctrl + F2`** instead
- Hold or tap repeatedly during boot

### Method 2: SSH Reboot to BIOS (Easiest!)

**If you can SSH into UGOS:**
```bash
ssh pete@192.168.0.158
sudo systemctl reboot --firmware-setup
```

**This will:**
- Reboot NAS
- Automatically enter BIOS
- No key pressing needed!

## 🎯 What You Should See

**Boot Menu (Ctrl+F12):**
- List of bootable devices
- USB drive should be listed
- Select with arrow keys, press Enter

**BIOS Setup (Ctrl+F2):**
- Full BIOS/UEFI interface
- Menu tabs: Main, Advanced, Boot, Security, Save & Exit
- Can configure all settings

## ⚠️ Important Notes

**Why Standard Keys Don't Work:**
- DXP2800 is designed as headless device
- Standard F2/Delete are intercepted by GRUB
- Requires modifier key (Ctrl) combination

**Timing:**
- Press keys **immediately** when powering on
- Before Ugreen logo appears
- Before GRUB loads

## 🔧 Current Situation

**You're seeing GRUB menu** because:
- Standard keys (F2/Delete) go to GRUB
- Need to use **Ctrl+F12** or **Ctrl+F2** instead
- Or use SSH method to reboot into BIOS

## ✅ Recommended Next Steps

**Option 1: Try Ctrl+F12 (Boot Menu)**
- Reboot NAS
- Press **Ctrl+F12** immediately
- Select USB from boot menu

**Option 2: Use SSH Method (Easiest)**
```bash
ssh pete@192.168.0.158 "sudo systemctl reboot --firmware-setup"
```
- This reboots directly into BIOS
- No key pressing needed!

---

**Try the SSH method first - it's the most reliable!**

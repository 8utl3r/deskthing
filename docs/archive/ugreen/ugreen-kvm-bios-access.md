# Using KVM for BIOS Access on Ugreen DXP2800

**Great news!** A KVM (Keyboard-Video-Mouse) device is perfect for BIOS access and TrueNAS installation.

## ✅ KVM Compatibility

**KVM will work for:**
- ✅ BIOS/UEFI access (keyboard navigation)
- ✅ BIOS configuration (all settings)
- ✅ TrueNAS installer (keyboard/mouse)
- ✅ TrueNAS setup and configuration
- ✅ Ongoing management (if KVM stays connected)

**Advantages:**
- Remote access to BIOS (no need to be physically at NAS)
- Can see BIOS screen remotely
- Full keyboard/mouse control
- Perfect for headless NAS management

## 🔌 USB Power Settings

### Option 1: BIOS USB Power Settings

**In BIOS, look for:**
- `Advanced → USB Configuration → USB Power`
- `Advanced → USB Configuration → USB Always On`
- `Advanced → Power Management → USB Power`
- `Advanced → Chipset → USB Power Management`

**Set to:**
- `Enabled` or `Always On` or `On`
- Disable: `USB Selective Suspend` or `USB Power Saving`

### Option 2: UGOS USB Power Settings

**Via SSH (current UGOS):**
```bash
# Check current USB power settings
ssh pete@192.168.0.158 "cat /sys/module/usbcore/parameters/autosuspend 2>/dev/null || echo 'Checking...'"

# Disable USB autosuspend (keeps USB powered)
ssh pete@192.168.0.158 "echo -1 | sudo tee /sys/module/usbcore/parameters/autosuspend"
```

**Note**: This setting may reset after reboot. Better to set in BIOS.

### Option 3: Check Current USB Power State

```bash
# Check if USB ports are powered
ssh pete@192.168.0.158 "lsusb 2>/dev/null || ls /sys/bus/usb/devices/ | head -10"

# Check USB power management
ssh pete@192.168.0.158 "cat /sys/bus/usb/devices/*/power/control 2>/dev/null | head -5"
```

## 📋 BIOS Access via KVM - Step by Step

### 1. Connect KVM
- KVM should already be connected to NAS USB ports
- Connect KVM to your Mac/computer
- KVM should show video output

### 2. Access BIOS via KVM
- **Power on NAS** (or reboot)
- **Watch KVM screen** for Ugreen logo
- **Press BIOS key** on KVM keyboard:
  - `F2` or `Delete` (most common)
  - Press repeatedly when logo appears
- **BIOS screen should appear** on KVM display

### 3. Navigate BIOS
- Use **KVM keyboard** to navigate (arrow keys)
- **Enter** to select menus
- **Esc** to go back
- **F10** to save and exit

### 4. Configure Settings
- Follow same steps as physical access
- Disable Watchdog Timer
- Set Boot Order
- Disable Secure Boot (optional)

### 5. Save and Exit
- Press **F10** (or use Save & Exit menu)
- Confirm with **Yes**
- NAS will reboot
- **KVM should show boot process**

## 🔧 USB Port Power Configuration

### In BIOS (Recommended - Permanent)

**Steps:**
1. Access BIOS via KVM
2. Navigate to: `Advanced → USB Configuration`
3. Look for:
   - `USB Power`: Set to `Enabled` or `Always On`
   - `USB Selective Suspend`: Set to `Disabled`
   - `USB Power Management`: Set to `Disabled` or `Off`
4. Save settings (F10)

**Common BIOS paths:**
- `Advanced → USB Configuration → USB Power → Enabled`
- `Advanced → Chipset → USB Configuration → USB Power → Always On`
- `Advanced → Power Management → USB Power → Enabled`

### Via UGOS (Temporary - Until Reboot)

```bash
# Disable USB autosuspend (keeps USB powered)
ssh pete@192.168.0.158 "echo -1 | sudo tee /sys/module/usbcore/parameters/autosuspend"

# Verify
ssh pete@192.168.0.158 "cat /sys/module/usbcore/parameters/autosuspend"
# Should show: -1 (disabled)
```

**Note**: This resets after reboot. Set in BIOS for permanent solution.

## 🎯 KVM-Specific Tips

### Keyboard Mapping
- Some KVMs may have different key mappings
- If `F2` doesn't work, try `Fn+F2` or check KVM manual
- USB keyboard should work normally in BIOS

### Video Resolution
- BIOS may output at different resolution than OS
- KVM should handle resolution switching automatically
- If screen is blank, try adjusting KVM display settings

### Mouse Support
- Mouse may not work in BIOS (keyboard-only navigation)
- This is normal - BIOS uses keyboard navigation
- Mouse will work once TrueNAS installer loads

## ✅ Verification Checklist

Before proceeding:
- [ ] KVM connected to NAS USB ports
- [ ] KVM connected to your Mac/computer
- [ ] KVM shows video output from NAS
- [ ] KVM keyboard works (test by typing)
- [ ] USB power set to "Always On" in BIOS (if available)

## 🚀 Next Steps

1. **Configure USB power** in BIOS (if option available)
2. **Access BIOS** via KVM
3. **Disable Watchdog Timer**
4. **Set Boot Order** (USB → NVMe → eMMC)
5. **Save and Exit**
6. **Insert TrueNAS USB**
7. **Boot from USB** (should see on KVM screen)
8. **Install TrueNAS** (all via KVM!)

## Troubleshooting KVM Issues

### KVM Not Showing Video
- Check KVM power/connections
- Try different USB port on NAS
- Check KVM display input settings
- Verify KVM is powered on

### Keyboard Not Working in BIOS
- Try different USB port
- Check if keyboard works in UGOS first
- Some KVMs need USB 2.0 port
- Try direct keyboard connection to test

### USB Ports Powering Off
- Set USB power to "Always On" in BIOS
- Disable USB power management
- Check BIOS power management settings
- May need to disable "USB Selective Suspend"

---

**Perfect setup!** With KVM, you can do everything remotely. Let me know when you're ready to access BIOS via KVM and I'll guide you through finding the USB power settings!

# KVM BIOS Access Walkthrough for Ugreen DXP2800

**Perfect!** Your KVM setup is ideal for BIOS access and TrueNAS installation.

## ✅ KVM Setup Confirmed

**Your KVM will work for:**
- ✅ BIOS/UEFI access (full keyboard navigation)
- ✅ BIOS configuration (all settings)
- ✅ TrueNAS installer (keyboard/mouse)
- ✅ TrueNAS setup and ongoing management

**Advantages:**
- Remote access - no need to be physically at NAS
- See BIOS screen on your Mac via KVM
- Full control via KVM keyboard/mouse
- Perfect for headless NAS management

---

## 🔌 USB Power Configuration

### Option 1: Configure in BIOS (Recommended - Permanent)

**When you access BIOS via KVM, look for:**

1. **Navigate to**: `Advanced → USB Configuration`
2. **Look for these settings**:
   - `USB Power`: Set to `Enabled` or `Always On`
   - `USB Selective Suspend`: Set to `Disabled`
   - `USB Power Management`: Set to `Disabled` or `Off`
   - `USB Always On`: Set to `Enabled`

**Common BIOS paths:**
- `Advanced → USB Configuration → USB Power → Enabled`
- `Advanced → Chipset → USB Configuration → USB Power → Always On`
- `Advanced → Power Management → USB Power → Enabled`

### Option 2: Temporary Fix via UGOS (Until Reboot)

**Via SSH (works now, but resets after reboot):**
```bash
# Disable USB autosuspend (keeps USB powered)
ssh pete@192.168.0.158 "echo -1 | sudo tee /sys/module/usbcore/parameters/autosuspend"

# Verify it worked
ssh pete@192.168.0.158 "cat /sys/module/usbcore/parameters/autosuspend"
# Should show: -1 (means disabled)
```

**Note**: This is temporary. Set it in BIOS for permanent solution.

---

## 📋 Step-by-Step: Access BIOS via KVM

### Step 1: Prepare KVM

1. **KVM should be connected**:
   - KVM USB to NAS USB port
   - KVM video to NAS HDMI
   - KVM connected to your Mac

2. **Verify KVM is working**:
   - Can you see UGOS desktop on KVM screen?
   - Does KVM keyboard work in UGOS?
   - If yes → KVM is ready!

### Step 2: Reboot and Enter BIOS

1. **Reboot NAS**:
   ```bash
   ssh pete@192.168.0.158 "sudo reboot"
   ```
   Or power cycle manually

2. **Watch KVM screen** for Ugreen logo

3. **Press BIOS key repeatedly**:
   - Try **`F2`** first (most common)
   - Or **`Delete`** key
   - Or **`F12`** (boot menu)
   - Press **repeatedly** as soon as logo appears

4. **BIOS screen should appear** on KVM display

### Step 3: Navigate BIOS with KVM Keyboard

- **Arrow keys**: Navigate menus
- **Enter**: Select/enter menu
- **Esc**: Go back
- **F10**: Save and exit (usually)
- **Tab**: Move between fields

---

## 🎯 BIOS Configuration Checklist

### 1. Configure USB Power (Keep KVM On)

**Navigate to**: `Advanced → USB Configuration`

**Set**:
- `USB Power`: `Enabled` or `Always On`
- `USB Selective Suspend`: `Disabled`
- `USB Power Management`: `Disabled`

**Save**: Press `F10` or go to `Save & Exit`

### 2. Disable Watchdog Timer ⚠️ CRITICAL

**Navigate to**: `Advanced → Watchdog` (or `Advanced → Chipset → Watchdog`)

**Set**: `Watchdog Timer`: `Disabled` or `Off`

**Why**: Prevents continuous reboots when TrueNAS is installed

### 3. Set Boot Order

**Navigate to**: `Boot → Boot Order`

**Set order**:
- **1st**: USB / Removable Device
- **2nd**: NVMe (your new drive)
- **3rd**: eMMC (UGOS - for rollback)

### 4. Disable Secure Boot (Optional)

**Navigate to**: `Security → Secure Boot`

**Set**: `Secure Boot`: `Disabled`

---

## 🎬 Live Walkthrough

**Ready? Let's do it step by step:**

1. **First, let's set USB power temporarily** (so KVM stays on):
   ```bash
   ssh pete@192.168.0.158 "echo -1 | sudo tee /sys/module/usbcore/parameters/autosuspend"
   ```

2. **Reboot NAS**:
   ```bash
   ssh pete@192.168.0.158 "sudo reboot"
   ```

3. **Watch KVM screen** - you should see boot process

4. **When Ugreen logo appears**, start pressing **`F2`** repeatedly

5. **BIOS should appear** on KVM screen

**Once you're in BIOS, tell me what you see and I'll guide you to each setting!**

---

## 🔍 What to Look For in BIOS

**Typical BIOS menu structure:**
```
┌─────────────────────────────────────┐
│  Main  Advanced  Boot  Security  Exit │
├─────────────────────────────────────┤
│                                     │
│  Advanced Menu:                    │
│  ├── CPU Configuration             │
│  ├── Chipset Configuration         │
│  │   └── Watchdog Timer ← FIND THIS│
│  ├── USB Configuration ← FIND THIS│
│  │   ├── USB Power                 │
│  │   └── USB Selective Suspend     │
│  └── Storage Configuration         │
│                                     │
└─────────────────────────────────────┘
```

---

## ✅ Quick Commands

**Set USB power temporarily (do this first):**
```bash
ssh pete@192.168.0.158 "echo -1 | sudo tee /sys/module/usbcore/parameters/autosuspend"
```

**Reboot to access BIOS:**
```bash
ssh pete@192.168.0.158 "sudo reboot"
```

**Then watch KVM screen and press F2 when logo appears!**

---

Ready to start? Let me know when you're ready to reboot and access BIOS, and I'll guide you through finding each setting!

# Ugreen DXP2800: KVM Keyboard Issues & BIOS Access Problems

## 🔴 Common Problem: Can't Access BIOS Through KVM

**You're not alone!** Many users report difficulty accessing BIOS on the DXP2800, especially through KVMs.

### Why KVMs Cause Problems

**KVMs often fail during BIOS access because:**
- BIOS/UEFI doesn't recognize keyboards through USB hubs/KVMs during POST
- USB controller initializes AFTER BIOS screen appears
- Timing issues: keys pressed too early/late aren't recognized
- Some KVMs don't pass through USB HID codes correctly

**This is a known issue with:**
- Jet KVM
- PiKVM
- Many hardware KVM switches
- USB-C KVMs

---

## ✅ Mac Keyboard Keycodes: Ctrl IS the Same!

**Good news:** Mac and PC keyboards use **identical USB HID scan codes** at the firmware level.

**Ctrl Key:**
- ✅ **Same keycode** on Mac and PC keyboards
- ✅ Should work identically in BIOS
- ✅ Physical position differs, but code is same

**Key Mappings:**
- **Mac Ctrl** = **PC Ctrl** (same HID code)
- **Mac Command (⌘)** = **PC Windows key** (same HID code)
- **Mac Option (⌥)** = **PC Alt** (same HID code)

**So `Ctrl+F2` should work the same from Mac or PC keyboard!**

**The problem is likely the KVM, not the keyboard.**

---

## 🔧 Solutions: Access BIOS Despite KVM Issues

### Solution 1: Direct USB Keyboard Connection (Most Reliable!)

**Bypass the KVM entirely:**

1. **Get a simple USB keyboard** (basic, no fancy drivers)
2. **Connect directly** to DXP2800 USB 2.0 port
3. **Reboot NAS**
4. **Press `Ctrl+F2`** immediately (before logo appears)
5. **BIOS should appear!**

**Why this works:**
- Direct USB connection = BIOS recognizes keyboard
- No KVM hub in the way
- USB 2.0 port = better compatibility than USB 3.0

**After accessing BIOS:**
- Enable "USB Legacy Support" (helps future KVM compatibility)
- Disable watchdog timer
- Save settings

### Solution 2: Use JetKVM Virtual Keyboard

**If using JetKVM:**

1. **Open JetKVM web interface**
2. **Use Virtual Keyboard** feature
3. **Send keystrokes directly** to remote machine
4. **May bypass KVM timing issues**

**Note:** JetKVM supports US keyboard layout only.

### Solution 3: Timing Tricks

**If keyboard works but timing is off:**

1. **Power on NAS**
2. **Wait 1-2 seconds** (let USB initialize)
3. **Then rapidly press** `Ctrl+F2` repeatedly
4. **Or try:** `F2`, `Delete`, `Esc` (common BIOS keys)

**Some systems need keys pressed AFTER USB initializes, not before!**

### Solution 4: Alternative BIOS Keys

**Try these instead of `Ctrl+F2`:**

- **`F2`** (most common)
- **`Delete`** or **`Del`**
- **`F1`**
- **`Esc`**
- **`F10`** (some systems)

**Check Ugreen documentation** for exact key combination.

---

## 🎯 Alternative: Disable Watchdog via IPMI (No BIOS Needed!)

**Even better solution:** Disable watchdog timer **from the OS** using IPMI commands!

### Method 1: Using `ipmitool` (Recommended)

**Once TrueNAS is installed (or from installer shell):**

```bash
# Check if watchdog is enabled
ipmitool mc watchdog get

# Disable watchdog timer
ipmitool mc watchdog off

# Verify it's disabled
ipmitool mc watchdog get
```

**Make it permanent** (add to TrueNAS startup):

1. **TrueNAS SCALE:** Add to Post-Init script:
   ```bash
   ipmitool mc watchdog off
   ```

2. **TrueNAS CORE:** Add to `/etc/rc.local`:
   ```bash
   ipmitool mc watchdog off
   ```

### Method 2: Using `bmc-watchdog` (FreeIPMI)

**More granular control:**

```bash
# Stop watchdog immediately
bmc-watchdog --stop

# Clear all watchdog configs
bmc-watchdog --clear

# Check status
bmc-watchdog --get

# Run as daemon (keeps watchdog disabled)
bmc-watchdog --daemon
```

### Why IPMI Works

**IPMI (Intelligent Platform Management Interface):**
- Communicates directly with BMC (Baseboard Management Controller)
- Can disable watchdog timer without BIOS access
- Works from OS level
- **No keyboard/KVM needed!**

**This is the best solution if BIOS access fails!**

---

## 📋 Step-by-Step: Disable Watchdog Without BIOS

### During TrueNAS Installation

**If installer has shell access:**

1. **Boot TrueNAS installer** (with watchdog disable parameters in GRUB)
2. **Open shell** (if available)
3. **Install ipmitool:**
   ```bash
   # May need to download or use installer tools
   ```
4. **Disable watchdog:**
   ```bash
   ipmitool mc watchdog off
   ```
5. **Continue installation**

### After TrueNAS Installation

**Once TrueNAS is running:**

1. **SSH into TrueNAS**
2. **Install ipmitool** (if not already installed):
   ```bash
   # TrueNAS SCALE (Debian-based)
   apt-get update && apt-get install -y ipmitool
   
   # TrueNAS CORE (FreeBSD-based)
   pkg install ipmitool
   ```
3. **Disable watchdog:**
   ```bash
   ipmitool mc watchdog off
   ```
4. **Make permanent** (add to startup scripts)
5. **Reboot** - watchdog should stay disabled!

---

## 🚨 Known Issues with Ugreen DXP2800

**From community reports:**

1. **Locked BIOS:** Some users report BIOS is locked/restricted
2. **Soldered Storage:** UGOS on soldered SSD complicates OS replacement
3. **Watchdog Aggressive:** Watchdog re-enables on reboot (need startup script)
4. **KVM Compatibility:** Many KVMs don't work during POST

**Solutions:**
- Use IPMI to disable watchdog (bypasses BIOS)
- Direct USB keyboard for BIOS access
- Add watchdog disable to startup scripts

---

## ✅ Recommended Approach

**Best strategy:**

1. **Try direct USB keyboard** first (bypass KVM)
2. **If BIOS access fails:** Use IPMI method instead
3. **Add watchdog disable to GRUB boot** (temporary during install)
4. **Add watchdog disable to startup script** (permanent after install)

**You don't need BIOS access if IPMI works!**

---

## 🔍 Troubleshooting

### Keyboard Not Working in BIOS

**Try:**
- Direct USB connection (bypass KVM)
- Different USB port (USB 2.0 preferred)
- Simple keyboard (no fancy drivers)
- Wait 1-2 seconds after power-on
- Try different BIOS keys (F2, Delete, Esc)

### IPMI Commands Not Working

**Check:**
- Is IPMI enabled in BIOS? (may need direct keyboard for this)
- Is `ipmitool` installed?
- Are you running as root/admin?
- Try `ipmitool mc info` to test IPMI connection

### Watchdog Still Reboots

**Even after disabling:**
- Watchdog may re-enable on reboot
- Add disable command to startup script
- Use `bmc-watchdog --daemon` to keep it disabled
- Check BIOS settings (if accessible)

---

**Bottom line:** **Ctrl keycode is the same on Mac/PC, but KVM is likely blocking BIOS access. Use direct USB keyboard OR disable watchdog via IPMI instead!**

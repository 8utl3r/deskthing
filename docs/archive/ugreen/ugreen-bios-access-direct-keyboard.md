# Accessing BIOS with Direct USB Keyboard - Step by Step

## 🎯 Goal: Disable Watchdog Timer in BIOS

**Why:** Watchdog timer causes reboots during TrueNAS installation. Disabling it in BIOS is the permanent fix.

---

## 📋 Pre-Flight Checklist

**Before starting:**
- [ ] Simple USB keyboard ready (basic, no fancy drivers)
- [ ] Keyboard connected to NAS USB 2.0 port (not USB 3.0)
- [ ] Monitor/KVM connected to see BIOS screen
- [ ] NAS is powered off or can be rebooted

**USB Port Selection:**
- ✅ **Use USB 2.0 port** (better compatibility)
- ❌ Avoid USB 3.0 ports (may not work in BIOS)
- USB 2.0 ports are usually marked or different color
- If unsure, try different ports

---

## 🚀 Step-by-Step: Access BIOS

### Step 1: Connect Keyboard Directly

1. **Unplug keyboard from KVM** (if connected)
2. **Plug keyboard directly** into NAS USB 2.0 port
   - Use a port on the back of the NAS
   - Avoid front panel ports if possible
   - USB 2.0 port preferred

3. **Verify connection:**
   - Keyboard lights should turn on (if it has LEDs)
   - Caps Lock/Num Lock should work

### Step 2: Power On / Reboot NAS

**If NAS is off:**
- Press power button
- **Immediately start pressing keys** (see Step 3)

**If NAS is running:**
- Reboot via SSH: `ssh admin@192.168.0.158` then `sudo reboot`
- Or power cycle: Turn off, wait 5 seconds, turn on
- **As soon as power comes on, start pressing keys**

### Step 3: Press BIOS Access Keys

**Timing is critical!**

**Method A: Immediate Press (Recommended)**
1. **As soon as NAS powers on**, immediately press and hold:
   - **`Ctrl + F2`** (most common for Ugreen)
   - Or try: **`F2`** alone
   - Or try: **`Delete`** or **`Del`**

2. **Keep pressing repeatedly** until BIOS appears
   - Don't wait - start pressing immediately
   - Press before any logo appears
   - Rapidly tap the key combination

**Method B: Wait Then Press**
1. **Power on NAS**
2. **Wait 1-2 seconds** (let USB initialize)
3. **Then rapidly press** `Ctrl+F2` or `F2` repeatedly
4. **Some systems need keys AFTER USB initializes**

**Try both methods** - different systems respond differently!

### Step 4: BIOS Should Appear

**What you should see:**
- BIOS/UEFI setup screen
- Menu options (Main, Advanced, Boot, etc.)
- Usually blue/gray background
- Text-based or graphical interface

**If BIOS doesn't appear:**
- See Troubleshooting section below
- Try different key combinations
- Try different USB port
- Try different keyboard

---

## ⚙️ Step 5: Navigate BIOS and Disable Watchdog

### Navigation

**Use keyboard:**
- **Arrow keys** - Navigate menus
- **Enter** - Select/enter submenu
- **Esc** - Go back/exit menu
- **F10** - Save and exit (usually)

### Find Watchdog Setting

**Navigate to:**
1. **Advanced** menu (use arrow keys)
2. Look for one of these:
   - **Watchdog** or **Watchdog Timer**
   - **Chipset → Watchdog**
   - **System Configuration → Watchdog**
   - **Power Management → Watchdog**
   - **Hardware Monitor → Watchdog**

**Common locations:**
- `Advanced → Watchdog → Disabled`
- `Advanced → Chipset → Watchdog → Disabled`
- `Advanced → System Configuration → Watchdog → Disabled`

### Disable Watchdog

1. **Select Watchdog option** (Enter)
2. **Change value to**: **Disabled** or **Off**
   - Use arrow keys or +/- keys to change value
   - Some BIOS use Space to toggle
3. **Verify it says**: **Disabled** or **Off**

### Save and Exit

1. **Press `F10`** (Save and Exit)
2. **Confirm**: Yes/Save (usually Enter or Y)
3. **NAS will reboot**

---

## ✅ Step 6: Verify Success

**After reboot:**

1. **Watchdog should be disabled**
2. **TrueNAS installation should proceed without reboots**
3. **You can now install TrueNAS normally**

**To verify watchdog is disabled:**
- Try installing TrueNAS - it shouldn't reboot
- Or access BIOS again and check the setting

---

## 🚨 Troubleshooting

### BIOS Doesn't Appear

**Try these:**

1. **Different key combinations:**
   - `Ctrl + F2`
   - `F2` alone
   - `Delete` or `Del`
   - `F1`
   - `Esc`
   - `Ctrl + Alt + Esc`

2. **Different timing:**
   - Press immediately on power-on
   - Wait 1-2 seconds, then press
   - Rapidly tap keys repeatedly

3. **Different USB port:**
   - Try USB 2.0 port (if using USB 3.0)
   - Try different port on back of NAS
   - Try front panel port

4. **Different keyboard:**
   - Try another USB keyboard
   - Use basic keyboard (no fancy drivers)
   - Avoid wireless keyboards

5. **Check KVM/monitor:**
   - Make sure you can see the screen
   - BIOS may appear on different output
   - Try direct monitor connection

### Keyboard Not Working in BIOS

**Symptoms:**
- BIOS appears but keyboard doesn't respond
- Can't navigate menus

**Solutions:**
- Try different USB port
- Try different keyboard
- Check if "USB Legacy Support" is disabled (may need to enable)
- Some keyboards need USB 2.0 port

### Watchdog Option Not Found

**If you can't find Watchdog setting:**

1. **Check all Advanced submenus:**
   - Chipset
   - System Configuration
   - Power Management
   - Hardware Monitor
   - Security

2. **May be named differently:**
   - "TCO Timer"
   - "Hardware Watchdog"
   - "System Watchdog"
   - "BMC Watchdog"

3. **If still not found:**
   - BIOS version may not have option
   - May need BIOS update
   - Use Option 3 (GRUB boot parameters) instead

### Still Can't Access BIOS

**Fallback options:**

1. **Use Option 3:** Add watchdog disable to GRUB boot parameters
   - No BIOS access needed
   - Works for installation
   - Disable permanently after install via IPMI

2. **Try JetKVM Virtual Keyboard:**
   - Open JetKVM web interface
   - Use Virtual Keyboard feature
   - Send keystrokes directly

3. **Contact Ugreen support:**
   - May have specific BIOS access method
   - May need firmware update

---

## 📝 Quick Reference

**BIOS Access Keys (try in order):**
1. `Ctrl + F2` (most common)
2. `F2`
3. `Delete` / `Del`
4. `F1`
5. `Esc`

**Watchdog Location:**
- `Advanced → Watchdog → Disabled`

**Save BIOS:**
- `F10` → Confirm

**Navigation:**
- Arrow keys: Move
- Enter: Select
- Esc: Back

---

## 🎯 Success Criteria

**You've succeeded when:**
- ✅ BIOS screen appears
- ✅ Can navigate menus with keyboard
- ✅ Found Watchdog setting
- ✅ Set to Disabled
- ✅ Saved settings (F10)
- ✅ NAS reboots
- ✅ TrueNAS installation doesn't reboot

---

**Ready to try? Connect your keyboard directly to NAS USB 2.0 port and reboot!**

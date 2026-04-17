# Ugreen DXP2800 Watchdog Timer Reboot Issue

## 🔴 Problem: Continuous Reboots

**What's happening:**
- NAS keeps rebooting every few minutes
- Happens during TrueNAS installation
- Happens when UGOS isn't running

**Root Cause:** **Watchdog Timer**

## ⚠️ Why Watchdog Causes Reboots

**The DXP2800 has a hardware watchdog timer that:**
- Expects UGOS to send a "heartbeat" signal
- If heartbeat stops → assumes system crashed
- Forces hardware reset/reboot
- **This is why it keeps rebooting!**

**When it triggers:**
- ✅ During BIOS setup (UGOS not running)
- ✅ During TrueNAS installation (UGOS not running)
- ✅ After TrueNAS installs (UGOS replaced)
- ❌ When UGOS is running normally

## 🔧 Solution: Disable Watchdog Timer

**Must be done in BIOS** - cannot be disabled from OS level reliably.

**BIOS Location:**
- `Advanced → Watchdog` → Set to `Disabled`
- Or `Advanced → Chipset → Watchdog` → `Disabled`
- Or `Advanced → System Configuration → Watchdog` → `Disabled`

## 🚀 Temporary Workaround: Boot Parameters

**We can try to disable watchdog via kernel parameters:**

**In GRUB, when booting TrueNAS, add:**
```grub
set root=(hd0)
linux /vmlinuz boot=live components quiet iTCO_wdt.force_no_reboot=1
initrd /initrd.img
boot
```

**Or:**
```grub
set root=(hd0)
linux /vmlinuz boot=live components quiet iTCO_wdt.force_no_reboot=1 acpi=noirq
initrd /initrd.img
boot
```

**These parameters:**
- `iTCO_wdt.force_no_reboot=1` - Disables Intel watchdog
- May prevent reboots during installation

## 📋 Access BIOS to Disable Watchdog

**Since firmware-setup didn't work, try keyboard method:**

1. **Reboot NAS**
2. **Immediately press and hold**: **`Ctrl + F2`**
   - Press BEFORE any logo appears
   - Hold or tap repeatedly
3. **BIOS should appear**
4. **Navigate to**: `Advanced → Watchdog`
5. **Set to**: `Disabled`
6. **Save**: Press `F10`
7. **Reboot**

**Then TrueNAS installation can proceed without reboots!**

---

## 🎯 Current Situation

**You're experiencing watchdog reboots because:**
- Watchdog timer is still enabled in BIOS
- TrueNAS installer doesn't send UGOS heartbeat
- Watchdog forces reboot every few minutes

**Solutions:**
1. **Disable watchdog in BIOS** (permanent fix)
2. **Add watchdog disable parameter** to GRUB boot (temporary)
3. **Install quickly** before watchdog triggers (risky)

---

**Let's try accessing BIOS with Ctrl+F2, or add the watchdog disable parameter to GRUB boot!**

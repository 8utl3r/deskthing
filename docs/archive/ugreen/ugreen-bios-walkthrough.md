# Ugreen DXP2800 BIOS Configuration Walkthrough

**Goal**: Configure BIOS to allow TrueNAS Scale installation  
**Time**: 5-10 minutes  
**Difficulty**: Easy (just need to find the right menus)

---

## 🎯 What We Need to Change

1. **Disable Watchdog Timer** ⚠️ CRITICAL
2. **Set Boot Order** (USB → NVMe → eMMC)
3. **Optional: Disable Secure Boot** (recommended)

---

## Step 1: Access BIOS

### 1.1 Power On the NAS
- Make sure NAS is powered off
- Connect monitor and keyboard to NAS
- Power on the NAS

### 1.2 Enter BIOS
- **As soon as you see the Ugreen logo**, start pressing:
  - Try **`F2`** first (most common)
  - Or **`Delete`** key
  - Or **`F12`** (boot menu)
  - Or **`Esc`**
- **Press repeatedly** until BIOS screen appears
- If you see Windows/UGOS loading, you missed it - reboot and try again

### 1.3 What You Should See
- BIOS/UEFI setup screen (usually blue/gray background)
- Menu options at top: `Main`, `Advanced`, `Boot`, `Security`, `Save & Exit`
- May say "UEFI Setup" or "BIOS Setup" at top

---

## Step 2: Disable Watchdog Timer ⚠️ CRITICAL

**Why**: Watchdog forces reboot if UGOS not detected. Without disabling this, TrueNAS will reboot continuously.

### 2.1 Navigate to Advanced Menu
- Use **arrow keys** to move to **`Advanced`** tab
- Press **Enter** to enter the menu

### 2.2 Find Watchdog Setting
Look for one of these paths:
- `Advanced → Watchdog` or `Watchdog Timer`
- `Advanced → Chipset → Watchdog`
- `Advanced → System Configuration → Watchdog`
- `Advanced → Hardware Monitor → Watchdog`
- `Advanced → Power Management → Watchdog`

**What to look for**:
- Options like: `Watchdog`, `Watchdog Timer`, `Hardware Watchdog`
- Current value might be: `Enabled`, `On`, or `Auto`

### 2.3 Disable Watchdog
- Navigate to the Watchdog option (arrow keys)
- Press **Enter** to change value
- Select **`Disabled`** or **`Off`**
- Press **Enter** to confirm

### 2.4 Verify
- Should now show: `Watchdog: Disabled` or `Watchdog: Off`
- If you can't find it, note the menu structure and we'll troubleshoot

---

## Step 3: Set Boot Order

### 3.1 Navigate to Boot Menu
- Press **Esc** to go back to main menu (if needed)
- Use **arrow keys** to move to **`Boot`** tab
- Press **Enter** to enter the menu

### 3.2 Find Boot Order Settings
Look for:
- `Boot Order` or `Boot Priority`
- `Boot Sequence`
- `Boot Device Priority`
- May be numbered: `1st Boot Device`, `2nd Boot Device`, etc.

### 3.3 Set Boot Order
Set the order to:
1. **USB** or **Removable Device** or **USB Hard Disk**
2. **NVMe** or **M.2** or your NVMe drive name
3. **eMMC** or **Internal Storage**

**How to change**:
- Navigate to each boot device option
- Press **Enter** or **+/-** to change
- Select from dropdown list
- Or use **F5/F6** to move items up/down

### 3.4 Alternative: Boot Override (One-Time Boot)
If you can't change permanent boot order:
- Look for **`Boot Override`** or **`Boot Menu`**
- Select **USB** or **Removable Device**
- This boots from USB once without changing permanent settings

---

## Step 4: Disable Secure Boot (Optional but Recommended)

### 4.1 Navigate to Security Menu
- Press **Esc** to go back to main menu
- Use **arrow keys** to move to **`Security`** tab
- Press **Enter**

### 4.2 Find Secure Boot
- Look for **`Secure Boot`** option
- May be under: `Secure Boot Configuration` or `Boot Security`

### 4.3 Disable Secure Boot
- Navigate to **`Secure Boot`**
- Press **Enter**
- Select **`Disabled`** or **`Off`**
- Press **Enter** to confirm

**Note**: Some BIOS may require setting a supervisor password first. If prompted, you can set a temporary password or skip this step.

---

## Step 5: Save and Exit

### 5.1 Navigate to Save & Exit
- Press **Esc** to go back to main menu
- Use **arrow keys** to move to **`Save & Exit`** tab
- Press **Enter**

### 5.2 Save Changes
- Look for: **`Save Changes and Exit`** or **`Save Configuration`**
- Press **Enter**
- Confirm: **`Yes`** when prompted

**Or use shortcut**: Press **`F10`** from anywhere in BIOS, then confirm

### 5.3 System Will Reboot
- BIOS will save settings
- System will reboot
- **Don't press any keys** - let it boot normally
- If USB is inserted, it should try to boot from USB

---

## 🎯 Quick Reference Checklist

Before leaving BIOS, verify:

- [ ] **Watchdog Timer**: `Disabled` ✅
- [ ] **Boot Order**: USB → NVMe → eMMC ✅
- [ ] **Secure Boot**: `Disabled` (optional) ✅
- [ ] **Settings Saved**: Pressed F10 or Save & Exit ✅

---

## 🚨 Troubleshooting

### Can't Find Watchdog Option

**Try these locations**:
1. `Advanced → Chipset Configuration → Watchdog`
2. `Advanced → System Configuration → Watchdog`
3. `Advanced → Hardware Monitor → Watchdog`
4. `Advanced → Power Management → Watchdog`
5. `Advanced → South Bridge → Watchdog`

**If still not found**:
- May be in different BIOS version
- Note: If TrueNAS reboots continuously after install, watchdog is likely the issue
- Can try installing anyway and disable later if needed

### USB Not in Boot Order

**Solutions**:
- Use **USB 2.0 port** (USB 3.0 may not work in BIOS)
- Try different USB port
- Enable **"Legacy USB Support"** in Advanced → USB Configuration
- Use **Boot Override** for one-time boot

### Can't Save Changes

**Solutions**:
- Make sure you're in **Save & Exit** menu
- Some BIOS require **Enter** after selecting "Save"
- Check if BIOS is "locked" - may need to clear CMOS
- Try **F10** shortcut from main menu

### Boot Order Not Saving

**Solutions**:
- Make sure to press **F10** or select **Save & Exit**
- Some BIOS require selecting boot device, then pressing **Enter**
- Try **Boot Override** instead for one-time boot

---

## 📸 What to Look For (Visual Guide)

### Typical BIOS Layout:
```
┌─────────────────────────────────────────┐
│  Main  Advanced  Boot  Security  Exit  │  ← Menu tabs
├─────────────────────────────────────────┤
│                                         │
│  Advanced Menu:                         │
│  ├── CPU Configuration                  │
│  ├── Chipset Configuration              │
│  │   └── Watchdog Timer ← HERE!        │
│  ├── Storage Configuration              │
│  └── USB Configuration                  │
│                                         │
└─────────────────────────────────────────┘
```

### Boot Order Example:
```
Boot Order:
  1st Boot Device: [USB]        ← Select this
  2nd Boot Device: [NVMe]       ← Then this
  3rd Boot Device: [eMMC]       ← Then this
```

---

## ✅ After BIOS Configuration

Once BIOS is configured and saved:

1. **Insert TrueNAS USB** into NAS (USB 2.0 port recommended)
2. **Reboot** (or power on if off)
3. **System should boot from USB**
4. **TrueNAS installer should load**
5. **Proceed with TrueNAS installation**

---

## 🔄 Rollback Plan

If you need to return to UGOS:

1. **Access BIOS** (same method: F2/Delete during boot)
2. **Change boot order** to eMMC first
3. **Save and reboot**
4. **UGOS should boot normally**

Or remove NVMe drive and boot from eMMC.

---

## Next Steps After BIOS

1. ✅ BIOS configured
2. ⏭️ Boot from TrueNAS USB
3. ⏭️ Install TrueNAS Scale to NVMe
4. ⏭️ Configure TrueNAS

---

**Need help?** If you get stuck at any step, let me know what you see on screen and I can help troubleshoot!

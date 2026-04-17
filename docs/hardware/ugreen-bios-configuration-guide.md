# Ugreen DXP2800 BIOS Configuration Guide

**Purpose**: Configure BIOS settings before installing TrueNAS Scale to ensure successful installation and operation.

## ⚠️ Important Notes

- **BIOS access requires physical access** - Cannot be done remotely via SSH
- **You'll need**: Monitor/keyboard connected to NAS, or IPMI/KVM if available
- **Timing**: Access BIOS during boot, before OS loads
- **Changes needed**: Disable watchdog timer, set boot order

## Step-by-Step BIOS Access

### 1. Power On and Access BIOS

**Official BIOS Access Methods (from Ugreen documentation):**

**Method 1: Keyboard Combination (During Boot)**
1. **Power on the DXP2800 NAS**
2. **Immediately press and hold**: **`Ctrl + F12`** (Boot Menu) or **`Ctrl + F2`** (BIOS Setup)
   - Press keys together, or rapidly tap repeatedly
   - Start pressing BEFORE any logo appears
   - Standard F2/Delete keys are intercepted by GRUB - must use Ctrl modifier

**Method 2: SSH Reboot to BIOS (Recommended - Easiest!)**
```bash
ssh pete@192.168.0.158
sudo systemctl reboot --firmware-setup
```
- This reboots directly into BIOS/UEFI setup
- No key pressing needed!
- Most reliable method

3. **If you miss it**: Reboot and try again, or use SSH method

### 2. Navigate BIOS Menus

Once in BIOS/UEFI:
- Use **arrow keys** to navigate
- **Enter** to select/enter menus
- **Esc** to go back
- **F10** to save and exit (usually)

## Critical BIOS Settings

### ⚠️ CRITICAL: Disable Watchdog Timer

**Why**: The watchdog timer forces reboot if UGOS is not detected. This will cause TrueNAS to reboot continuously.

**Steps**:
1. Navigate to **Advanced** menu
2. Look for **Watchdog** or **Watchdog Timer** option
3. Set to **Disabled** or **Off**
4. **Save this setting** (usually F10)

**Location examples**:
- `Advanced → Watchdog → Disabled`
- `Advanced → Chipset → Watchdog → Disabled`
- `Advanced → System Configuration → Watchdog → Disabled`

### Set Boot Order

**Why**: Need to boot from USB installer first, then NVMe after installation.

**Steps**:
1. Navigate to **Boot** menu
2. Find **Boot Order** or **Boot Priority** settings
3. Set order to:
   - **1st**: USB / Removable Device
   - **2nd**: NVMe (your new drive)
   - **3rd**: eMMC (UGOS - for rollback)
4. **Save settings**

**Alternative**: Some BIOS have "Boot Override" - you can select USB for one-time boot without changing permanent order.

### Optional: Disable Secure Boot

**Why**: Some Linux installers have issues with Secure Boot enabled.

**Steps**:
1. Navigate to **Security** or **Boot** menu
2. Find **Secure Boot** option
3. Set to **Disabled**
4. **Save settings**

### Optional: Disable eMMC (If Installing on NVMe)

**Why**: Prevents boot conflicts, keeps UGOS intact for rollback.

**Steps**:
1. Navigate to **Advanced → Storage** or **Advanced → SATA Configuration**
2. Find **eMMC** option
3. Set to **Disabled**
4. **Save settings**

**Note**: This is optional - you can leave eMMC enabled and just set boot order.

## BIOS Menu Structure (Typical)

```
Main
├── System Information
│   ├── Processor: Intel N100
│   ├── Memory: 8GB
│   └── Storage: eMMC, NVMe, SATA
│
Advanced
├── CPU Configuration
├── Chipset Configuration
├── Watchdog Timer ← DISABLE THIS
├── Storage Configuration
│   ├── SATA Controller: Enabled
│   ├── NVMe: Enabled
│   └── eMMC: Enabled (or Disabled)
└── USB Configuration
│
Boot
├── Boot Mode: UEFI
├── Boot Order
│   ├── 1st: USB
│   ├── 2nd: NVMe
│   └── 3rd: eMMC
├── Boot Override: [Select USB for one-time boot]
└── Secure Boot: Disabled
│
Security
├── Secure Boot: Disabled
└── TPM: (leave as-is)
│
Save & Exit
├── Save Changes and Exit ← Use this when done
└── Discard Changes and Exit
```

## Verification Checklist

Before proceeding to TrueNAS installation, verify:

- [ ] Watchdog Timer: **Disabled**
- [ ] Boot Order: USB → NVMe → eMMC
- [ ] Secure Boot: **Disabled** (optional but recommended)
- [ ] USB ports: Enabled (for installer)
- [ ] NVMe: Detected and enabled
- [ ] Settings saved (F10)

## Troubleshooting

### Can't Access BIOS

**Solutions**:
- Try different keys: `F2`, `F12`, `Delete`, `Esc`
- Press key repeatedly during boot
- Try holding key before powering on
- Check Ugreen documentation for specific key
- Some systems: `Ctrl+F12` or `Ctrl+Alt+Esc`
- **KVM Issues**: If using KVM, try direct USB keyboard connection (bypasses KVM)
- **Mac Keyboard**: Ctrl keycode is same on Mac/PC, but KVM may block it
- **Alternative**: Use IPMI to disable watchdog (no BIOS needed) - see below

### Can't Access BIOS Through KVM

**Common problem!** Many KVMs don't pass keyboard input during POST.

**Solutions**:
1. **Direct USB keyboard** - Connect simple USB keyboard directly to NAS (bypasses KVM)
2. **Use USB 2.0 port** - Better compatibility than USB 3.0
3. **Wait 1-2 seconds** after power-on before pressing keys
4. **Try JetKVM Virtual Keyboard** - May bypass timing issues
5. **Use IPMI method** - Disable watchdog without BIOS access (see below)

### Alternative: Disable Watchdog via IPMI (No BIOS Needed!)

**If BIOS access fails through KVM, use IPMI instead:**

**Once TrueNAS is installed (or from installer shell):**

```bash
# Install ipmitool (if not already installed)
# TrueNAS SCALE:
apt-get update && apt-get install -y ipmitool

# TrueNAS CORE:
pkg install ipmitool

# Disable watchdog timer
ipmitool mc watchdog off

# Verify it's disabled
ipmitool mc watchdog get
```

**Make it permanent** (add to startup scripts):
- **TrueNAS SCALE**: Add `ipmitool mc watchdog off` to Post-Init script
- **TrueNAS CORE**: Add to `/etc/rc.local`

**This bypasses BIOS entirely!** See `docs/ugreen-kvm-keyboard-issues.md` for details.

### Watchdog Option Not Found

**Possible locations**:
- `Advanced → Chipset → Watchdog`
- `Advanced → System Configuration → Watchdog`
- `Advanced → Power Management → Watchdog`
- `Advanced → Hardware Monitor → Watchdog`

**If still not found**:
- May be in different BIOS version
- May need BIOS update
- Can try installing TrueNAS anyway - if it reboots continuously, watchdog is the issue

### Boot Order Not Saving

**Solutions**:
- Make sure to press **F10** to save
- Some BIOS require **Enter** after selecting boot order
- Try "Boot Override" for one-time USB boot
- Check if BIOS has "Lock" feature preventing changes

### USB Not Detected in Boot Order

**Solutions**:
- Use USB 2.0 port (USB 3.0 may not work in BIOS)
- Try different USB port
- Ensure USB drive is bootable
- Some BIOS: Enable "Legacy USB Support" in Advanced menu

## After BIOS Configuration

Once BIOS is configured:

1. **Insert TrueNAS USB installer**
2. **Reboot** (or power on)
3. **System should boot from USB**
4. **TrueNAS installer should load**
5. **Proceed with TrueNAS installation**

## Rollback Plan

If you need to return to UGOS:

1. **Access BIOS** (same method as above)
2. **Change boot order** to eMMC first
3. **Save and reboot**
4. **UGOS should boot normally**

Or:

1. **Remove NVMe drive** (if installed there)
2. **Boot from eMMC** (UGOS)
3. **Restore backup** if needed: `dd if=/volume1/ugos_backup.img of=/dev/mmcblk0`

## Next Steps After BIOS Configuration

1. ✅ BIOS configured
2. ⏭️ Create bootable USB from ISO
3. ⏭️ Boot from USB
4. ⏭️ Install TrueNAS Scale to NVMe
5. ⏭️ Configure TrueNAS

---

**Note**: If you have IPMI/KVM access, you can configure BIOS remotely. Otherwise, physical access with monitor/keyboard is required.

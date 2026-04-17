# Ugoos SK1: Flash Android 14 (2.0.x)

**Prerequisites:** Windows PC at 192.168.0.47 with SSH access (see `scripts/windows-pc/ssh-windows.sh`).

---

## 1. Gather Hardware

| Item | Notes |
|------|-------|
| **USB-A to USB-A OTG cable** | SK1 uses USB-A, not Type-C |
| **12V power adapter** | SK1's stock adapter |
| **Toothpick** | Recovery button is inside the 3.5 mm audio jack |

---

## 2. Install AML Burning Tool on Windows

**Required:** Aml_Burn_Tool version **3.2.8 or higher**.

- **Option A:** Some Ugoos firmware archives include Aml_Burn_Tool—check after unpacking.
- **Option B:** Download separately from [chinagadgetsreviews.com](https://chinagadgetsreviews.com/download-amlogic-usb-burning-tool-latest-version-3-2-8.html) or similar.

During install, **allow** the Amlogic driver installation (required for device detection).

---

## 3. Download Firmware

**Recommended for initial flash (fewest issues):** v2.0.1 (first Android 14 release)

- **URL:** https://mega.nz/file/axFURa4Y#novWMZNJzsdh8gHf0lsePq_wZ9yO0LpgS2nWwfEyU48
- **Size:** ~1.1 GB (7z archive)
- **Contents:** `.img` file, Aml_Burn_Tool v3.3.4

Download on the Windows PC (or transfer via KVM File Sharing). Unpack the 7z archive.

**Alternative (if 2.0.1 fails):** v2.0.4 with stability improvements: https://mega.nz/file/Lltg3bjL#PtPJLxLnj6VHku9O4NuYBCgFtyBvnGq7qhXNNC-GOzc

**After successful boot — OTA to 2.0.6 (verified path):**  
You must step through versions. Local update: Settings → About → System update → Local update. Use OTA zips from USB in order:

1. 2.0.1 → 2.0.2 (OTA from [product page](https://ugoos.com/ugoos-sk1-8-128-gb-amlogic-tvbox-s928x-k))
2. 2.0.2 → 2.0.5
3. 2.0.5 → 2.0.6

Download each OTA from the [Ugoos SK1 product page](https://ugoos.com/ugoos-sk1-8-128-gb-amlogic-tvbox-s928x-k) (Mega links). Unpack 7z archives; the zip inside is the OTA.

---

## 4. Flash Steps

1. **Run AML Burning Tool** on the Windows PC.
2. **Set language** if needed (menu).
3. **Load firmware:** Setting → Load Img → select the `.img` file.
4. **Click "Start"** in the tool.
5. **Connect SK1 to PC** via USB-A to USB-A OTG cable (do **not** connect power yet).
6. **Hold the Recovery button** (toothpick inside 3.5 mm jack).
7. **Connect power** to the SK1 while still holding Recovery.
8. **Keep holding Recovery** for ~5 seconds until the PC detects the device.
9. Flashing starts automatically. Wait for **"Burn Success"**.
10. **Disconnect** USB and power.

---

## 5. If PC Does Not Detect Device

- Check **Device Manager** for Amlogic drivers.
- Reinstall drivers from the Aml_Burn_Tool install directory if needed.
- Try a different USB port (USB 2.0 sometimes more reliable).
- Ensure you're holding Recovery **before** connecting power.

---

## 6. After Flash

- First boot may take a few minutes.
- **All user data is erased.** Set up from scratch.
- **OTA to 2.0.6:** Step through 2.0.2 → 2.0.5 → 2.0.6 (see firmware section above).
- **Burning tool settings:** If flash fails with "Fail in erase flash", uncheck **Erase Flash** and **Verify Bootloader**; keep **Reset After Burn** checked.
- Re-enable wireless ADB if needed: Settings → Developer options → Wireless debugging.

---

## Quick Reference

| Step | Action |
|------|--------|
| Cable | USB-A ↔ USB-A OTG |
| Recovery | Toothpick in 3.5 mm jack |
| Order | Hold Recovery → Connect power → Wait ~5 s |
| Success | "Burn Success" in tool |

---

## SSH to Windows

From your Mac:

```bash
~/dotfiles/scripts/windows-pc/ssh-windows.sh
```

Then on Windows, run the AML Burning Tool and follow the steps above.

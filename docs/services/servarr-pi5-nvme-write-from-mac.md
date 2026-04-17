# Pi 5 NVMe: Write from Mac (USB Enclosure)

**When:** NVMe removed from Pi, in USB–NVMe enclosure, connected to Mac.

---

## What's Ready

| Item | Location |
|------|----------|
| **Raspberry Pi OS image** | `~/Downloads/2025-12-04-raspios-trixie-arm64-lite.img.xz` |
| **Checksum** | `681a775e20b53a9e4c7341d748a5a8cdc822039d8c67c1fd6ca35927abbe6290` ✓ verified |

---

## Option A: Raspberry Pi Imager (recommended)

1. Open **Raspberry Pi Imager** on your Mac.
2. **Choose OS** → scroll down → **Use custom** → select:
   `~/Downloads/2025-12-04-raspios-trixie-arm64-lite.img.xz`
3. **Choose Storage** → select the **Samsung SSD 990 EVO Plus** (double-check it's the NVMe).
4. Click the **gear** (settings): hostname `servarr`, enable SSH, set user/password, Wi‑Fi if needed.
5. **Write** → wait for completion → **Safely eject**.
6. Put NVMe back in the Pi 5, power on.

---

## Option B: dd (command line)

```bash
# 1. List disks, find the NVMe (e.g. disk4)
diskutil list

# 2. Unmount it
diskutil unmountDisk /dev/disk4

# 3. Write (replace disk4 with your disk; use rdisk4 for faster writes)
xzcat ~/Downloads/2025-12-04-raspios-trixie-arm64-lite.img.xz | sudo dd of=/dev/rdisk4 bs=4m status=progress

# 4. Eject
diskutil eject /dev/disk4
```

**Note:** With `dd`, you won't get Imager's hostname/SSH/Wi‑Fi settings. Configure those after first boot (or use Imager).

---

## After Writing

1. Put the NVMe back in the Pi 5.
2. Power on. It should boot from NVMe.
3. SSH in: `ssh pi@servarr.local` (or `pi@<ip>` if hostname wasn't set).

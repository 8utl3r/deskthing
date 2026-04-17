# Servarr Pi 5: Prep Before the NVMe Arrives

**Purpose:** Do everything possible now so setup is faster once the Samsung 990 EVO Plus 1TB arrives.

---

## 1. Downloads (on your Mac)

Do these today so they’re ready tomorrow.

| Item | Where | Notes |
|------|--------|------|
| **Raspberry Pi Imager** | https://www.raspberrypi.com/software/ | Install on Mac. Use it to write OS to NVMe when the drive arrives (if you use a USB–NVMe enclosure). |
| **Raspberry Pi OS 64-bit Lite image** | https://downloads.raspberrypi.com/raspios_lite_arm64/images/ | Open the latest date folder, download `*.img.xz` (~500 MB). Lets you write to NVMe without waiting on Imager download. |
| **PiJARR setup script** (if using PiJARR) | `https://raw.githubusercontent.com/pijarr/pijarr/main/setup.sh` | Save as `pijarr-setup.sh`; copy to Pi later or run via `curl \| sh` when online. |

Optional (if you’ll use Docker): clone or download a Servarr + Gluetun docker-compose example (Gluetun supports Mullvad) and the AIOStreams `compose.yaml` + `.env.sample` from [AIOStreams](https://github.com/Viren070/AIOStreams) so you can edit them today.

---

## 2. Write NVMe from Mac (no SD card needed)

When the drive arrives:

1. Connect the **Samsung 990 EVO Plus** to your Mac via a **USB–NVMe enclosure** (M.2 2280).
2. Open **Raspberry Pi Imager** on the Mac.
3. Choose **Raspberry Pi OS (64-bit) → Lite** (no desktop).
4. Click the gear: set hostname (e.g. `servarr`), enable **SSH** (password or your SSH key), set user/password, optionally Wi-Fi.
5. Choose **Storage**: select the NVMe (will show as external drive). **Double-check the device** so you don’t overwrite your Mac disk.
6. Write. When it finishes, safely eject, put the NVMe in the Pi 5, and power on.

**If you don’t have a USB–NVMe enclosure:** You’ll need an SD card. Boot the Pi from SD (image written with Imager), insert the NVMe, then on the Pi run `rpi-imager` and write the OS to the NVMe; set boot order in `raspi-config`, then remove the SD and reboot.

**If the Pi doesn’t boot from NVMe:** Pi 5 may need EEPROM that prefers NVMe. Boot once from an SD card and run `raspi-config` → Advanced → Boot Order → NVMe.

---

## 3. Accounts (you already have / decide today)

- **Real-Debrid:** You’re already signed up — needed for AIOStreams (and optionally *arr).
- **Mullvad** (or another VPN): For Gluetun so qBittorrent’s traffic goes through the VPN. Get WireGuard config or OpenVPN credentials so Gluetun can be configured later. (Tailscale is separate — for *you* to access the Pi; it doesn’t replace Gluetun for torrent traffic.)
- **Domain:** **xcvr.link** — subdomains **listen.xcvr.link**, **watch.xcvr.link**, **read.xcvr.link**. If your home IP is dynamic, set up DDNS (router or ddclient) so `*.xcvr.link` (or each subdomain) points to your home IP.

---

## 4. On the Pi *Without* the NVMe (only if you have an SD card)

If you have **any** SD card and the Pi 5:

1. Use **Raspberry Pi Imager** on the Mac to write **Raspberry Pi OS Lite 64-bit** to the SD (same settings: hostname, SSH, user, Wi-Fi).
2. Boot the Pi from the SD, SSH in.
3. Run: `sudo apt update && sudo apt full-upgrade -y`
4. Run: `sudo rpi-update` (optional, for latest EEPROM/firmware).
5. Run: `sudo raspi-config` → **Advanced Options → Boot → Boot Order → NVMe/USB boot** (so when you later add the NVMe, it will prefer it).
6. Run: `sudo apt install -y rpi-imager` (so when the NVMe is in the Pi, you can write the OS from the Pi if you prefer).
7. Optionally create the data layout (only if you have another drive attached, e.g. USB): run the `servarr-pi5-create-data-dirs.sh` script (see below). Otherwise skip until the NVMe is in place.

After the NVMe arrives, you can either: (A) write the OS to the NVMe from the Mac (enclosure) as in section 2, or (B) boot from SD, insert NVMe, and use `rpi-imager` on the Pi to write the OS to `/dev/nvme0n1`, then shut down, remove SD, and boot from NVMe.

---

## 5. Files in This Repo You’ll Use Later

- **`docs/services/servarr-pi5-setup-plan.md`** — Full setup plan (phases 1–7).
- **`scripts/servarr-pi5-create-data-dirs.sh`** — Run on the Pi once to create TRaSH-style dirs under `/mnt/data` (or pass a path). Copy to Pi or run from a cloned dotfiles repo.
- **`docs/services/servarr-pi5-prep-before-drive.md`** — This file.
- **`scripts/servarr-pi5-day-one-commands.md`** — Ordered commands for first boot from NVMe (updates, data dirs, PiJARR or Docker).

---

## 6. Checklist for Tomorrow

- [ ] NVMe arrived; unwrap and inspect.
- [ ] If writing from Mac: USB enclosure connected, Imager wrote OS to NVMe, ejected safely, NVMe installed in Pi 5.
- [ ] If using SD first: SD in Pi, NVMe installed, boot from SD, write OS to NVMe with rpi-imager, set boot order, remove SD, reboot.
- [ ] Pi boots from NVMe; SSH works (hostname or IP).
- [ ] Run day-one commands (updates, create data dirs, install stack).
- [ ] Continue with `servarr-pi5-setup-plan.md` from Phase 3 onward.

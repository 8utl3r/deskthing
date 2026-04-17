# Hackboard 2 – Quick reference

Single-board PC: Intel Celeron N4020, 4–8 GB RAM, M.2 NVMe, HDMI 2.1, USB 3.0, Wi‑Fi/BT. Runs Windows 10/11 Pro or Linux.

## Power

- **12 V DC, 3 A minimum** (5.5 mm × 2.5 mm barrel, **center positive**).
- USB-C is **data only** — cannot power the board.
- Use included 12 V/3 A adapter or any 12 V ≥3 A supply with 5.5×2.5 mm center-positive plug.

## Quick start (first boot)

1. **Power** – Plug 12 V PSU into DC jack (no power button needed on some kits; board may power on when connected).
2. **Display** – HDMI to TV/monitor (4K HDMI 2.1 capable).
3. **Input** – USB keyboard (and mouse if desired); use one of the three USB 3.0 Type-A ports.
4. **Power on** – If there’s a power button (e.g. on case), press it; otherwise connect power and wait for boot.
5. **First boot** – Follow Windows OOBE or Linux installer/setup. Wi‑Fi can be configured during or after setup.

## Connectors (reminder)

- **DC in** – 5.5×2.5 mm, 12 V, center positive  
- **HDMI** – 4K60 capable (board supports up to 4K HDMI 2.1)  
- **USB 3.0** – 3× Type-A (keyboard, mouse, storage, etc.)  
- **USB Type-C** – Data only (no power/display)  
- **Optional** – M.2 NVMe, 40-pin GPIO (RPi‑style with adapter), eDP/touch, 4G/5G modem

## Notes / TODO

- [ ] Confirm OS preloaded (Windows vs Linux).
- [ ] Plan use case (desktop, kiosk, HA, dev, etc.) and document here.

# Servarr Pi 5: Day-One Commands

Run these **after** the Pi has booted from the NVMe and you can SSH in. Adjust hostname/user/paths as needed.

---

## 1. Update system

```bash
sudo apt update && sudo apt full-upgrade -y
```

---

## 2. Optional: update EEPROM/firmware

```bash
sudo rpi-update
# Reboot if it says so: sudo reboot
```

---

## 3. Set hostname (if not set by Imager)

```bash
sudo raspi-config
# System Options → Hostname → e.g. servarr
```

---

## 4. Create data layout

If using the script from this repo (copy to Pi or run from dotfiles):

```bash
sudo bash /path/to/servarr-pi5-create-data-dirs.sh
```

Or create manually (default base `/mnt/data`):

```bash
sudo mkdir -p /mnt/data/{torrents,media}/{movies,tv,music,books,audiobooks}
sudo chown -R "$USER:$USER" /mnt/data
```

If your media will live on the **same NVMe** (no separate USB drive), you can use a path like `/home/pi/data` or `/mnt/data`; if `/mnt/data` is a separate mount (e.g. USB HDD), mount that drive first, then run the script or mkdir against the mount point.

---

## 5. Install PiJARR (if using native stack)

```bash
sudo sh -c "$(wget -qO- https://raw.githubusercontent.com/pijarr/pijarr/main/setup.sh)"
# Choose "Install ALL" and follow prompts.
```

---

## 6. Or: install Docker (if using Docker stack)

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker "$USER"
# Log out and back in (or new SSH session) for group to apply.
```

---

## 7. Optional: static IP

Either reserve the Pi’s IP in your router (DHCP reservation) or set a static address:

```bash
sudo raspi-config
# System Options → Wireless LAN or Network Options → IP address
```

---

After this, continue with **`docs/services/servarr-pi5-setup-plan.md`** from Phase 3 (configure Prowlarr, *arrs, qBittorrent, then Jellyfin, Gelato, Caddy).

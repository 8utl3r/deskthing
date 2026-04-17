# Windows PC (192.168.0.47)

Scripts and reference for the Windows PC at 192.168.0.47 (DESKTOP-DB6DT8J). Used for Ugoos SK1 flashing (AML Burning Tool) and general PC management.

## Quick Reference

| Item | Value |
|------|-------|
| **Hostname** | DESKTOP-DB6DT8J |
| **IP** | 192.168.0.47 |
| **CPU** | Intel Celeron N5095 @ 2.00 GHz (4C/4T) |
| **RAM** | 8 GB (2×4 GB Samsung DDR4 3200) |
| **Storage** | 256 GB Kimtigo SSD (C:) |
| **Network** | Wi-Fi (Realtek 8821CE), 192.168.0.47/24 |

## SSH Access

```bash
~/dotfiles/scripts/windows-pc/ssh-windows.sh
~/dotfiles/scripts/windows-pc/ssh-windows.sh "hostname"
```

Requires `scripts/windows-pc/.env` with `WINDOWS_SSH_PASSWORD`. Copy from `.env.example`.

## System Inventory

Run inventory via SSH (saves TOC to local path):

```bash
~/dotfiles/scripts/windows-pc/run-inventory.sh
~/dotfiles/scripts/windows-pc/run-inventory.sh ~/Downloads/windows-TOC.md
```

Full inventory stored in `TOC.md` (see `docs/hardware/windows-pc-reference.md` for summary).

## Scripts

| Script | Purpose |
|--------|---------|
| `ssh-windows.sh` | SSH to Windows PC (password auth) |
| `run-inventory.sh` | Run system inventory via SSH |
| `run-inventory-rich.py` | Inventory with Rich progress |
| `windows-system-inventory.ps1` | PowerShell inventory (run on Windows) |
| `inventory-rich.py` | Python inventory wrapper (run on Windows) |
| `run-from-usb.ps1` | Run inventory from USB when plugged into PC |

## USB Drive

When using SK1Transfer USB with the PC: scripts are on the USB. Double-click `RUN_INVENTORY.bat` on the PC, or run inventory via SSH from Mac.

## Related

- `scripts/ugoos/` — Ugoos SK1 flashing (uses this PC for AML Burning Tool)
- `docs/hardware/windows-pc-reference.md` — Hardware summary
- `docs/hardware/windows-ssh-publickey-fix.md` — SSH setup notes

# Windows PC Reference (192.168.0.47)

Hardware and system reference for the Windows PC used for Ugoos SK1 flashing (AML Burning Tool) and general PC tasks.

## Identity

| Field | Value |
|-------|-------|
| **Hostname** | DESKTOP-DB6DT8J |
| **IP** | 192.168.0.47 |
| **Version** | T8PRO001 |

## Hardware

### Processor
- **Model** | Intel Celeron N5095 @ 2.00 GHz
- **Cores** | 4 physical, 4 logical
- **Max clock** | 2001 MHz

### Memory
- **Total** | 8 GB
- **Modules** | 2× Samsung 4 GB DDR4 3200
- **Slots** | Controller0-ChannelA, Controller0-ChannelB

### Storage
| Model | Size | Interface | Type |
|-------|------|-----------|------|
| Kimtigo SSD 256GB | 256 GB | IDE | Fixed |
| SanDisk 3.2Gen1 | 123 GB | SCSI/USB | Removable |

### Logical Drives
| Drive | Size | Free | FileSystem |
|-------|------|------|------------|
| C: | 237.58 GB | 185.34 GB | NTFS |

## Network

### Adapters
- **Wi-Fi** | Realtek 8821CE Wireless LAN 802.11ac PCI-E NIC
- **MAC** | E0-75-26-82-27-18
- **Link** | 200 Mbps

### IP Configuration
- **Wi-Fi** | 192.168.0.47/24 (primary)

## Firewall

- **Domain** | Enabled
- **Private** | Enabled
- **Public** | Enabled
- **Default actions** | NotConfigured

## Access

- **SSH** | `~/dotfiles/scripts/windows-pc/ssh-windows.sh`
- **Inventory** | `~/dotfiles/scripts/windows-pc/run-inventory.sh`
- **Full TOC** | `scripts/windows-pc/TOC.md`

## Related

- `scripts/ugoos/` — SK1 flashing workflow
- `docs/hardware/windows-ssh-publickey-fix.md` — SSH setup

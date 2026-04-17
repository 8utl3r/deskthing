# Ugreen DXP2800 Scripts

Scripts for managing and gathering information from the Ugreen DXP2800 NAS.

## Manual SSH Connection

Since automated password entry isn't working, please run this manually:

```bash
ssh Pete@192.168.0.158
# Enter password when prompted: n0ypSGlWEflFZr
```

## Gather System Information

Once connected via SSH, run these commands:

```bash
# System info
uname -a
cat /etc/os-release

# Disk layout
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE

# Network
ip addr show
lspci | grep -iE 'nvme|network|ethernet|intel'

# Storage
df -h
ls -la /dev/mmcblk* 2>/dev/null
ls -la /dev/nvme* 2>/dev/null
ls -la /dev/sd* 2>/dev/null

# System
hostname
uptime
```

## Setup SSH Keys (Recommended)

To avoid password prompts:

```bash
# Copy your SSH key
ssh-copy-id -i ~/.ssh/id_ed25519.pub Pete@192.168.0.158

# Or manually:
cat ~/.ssh/id_ed25519.pub | ssh Pete@192.168.0.158 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
```

## Scripts

- `ugreen-gather-info.sh` - Interactive script to gather system info
- `ugreen-auto-info.sh` - Automated script using expect (may need password fix)
- `ugreen-ssh-setup.sh` - SSH key setup script

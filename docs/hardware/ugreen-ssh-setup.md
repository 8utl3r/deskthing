# Ugreen DXP2800 SSH Setup & Preparation

## SSH Connection Details

**Device:** Ugreen DXP2800  
**IP:** 192.168.0.158  
**Port:** 22  
**Status:** ✅ SSH Enabled

## Authentication

SSH requires authentication. You'll need:
- **Username**: (Check UGOS web UI → Users to see admin username)
- **Password**: Your admin password

## Testing SSH Connection

Try connecting interactively:
```bash
ssh admin@192.168.0.158
# Or try:
ssh root@192.168.0.158
```

## Next Steps After SSH Access

Once you can SSH in, we'll:

1. **Check System Information**
   ```bash
   uname -a
   cat /etc/os-release
   lsblk
   ```

2. **Check Hardware**
   ```bash
   # List all disks
   lsblk
   
   # Check NVMe slots
   lspci | grep -i nvme
   ls -la /dev/nvme*
   
   # Check network interfaces
   ip addr show
   
   # Check eMMC (boot device)
   lsblk | grep mmcblk0
   ```

3. **Backup UGOS Firmware**
   ```bash
   # Identify eMMC device
   lsblk | grep mmcblk0
   
   # Check available space for backup
   df -h
   
   # Backup to external USB or network share
   # (We'll set this up once connected)
   ```

4. **Prepare for TrueNAS Installation**
   - Document current configuration
   - Check BIOS/UEFI info
   - Verify hardware compatibility

## SSH Key Authentication (Optional)

To avoid password prompts, you can set up SSH key authentication:

```bash
# On your Mac, generate key if needed
ssh-keygen -t ed25519 -C "ugreen-nas"

# Copy public key to UGOS
ssh-copy-id admin@192.168.0.158
# Or manually:
cat ~/.ssh/id_ed25519.pub | ssh admin@192.168.0.158 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

## Commands to Run Once Connected

Save these commands to run after SSH access:

```bash
# System info
uname -a
cat /etc/os-release
hostname
uptime

# Hardware info
lsblk
lspci | grep -i nvme
ip addr show
df -h

# Check if we can access eMMC
ls -la /dev/mmcblk*

# Check BIOS/UEFI
dmidecode -t system 2>/dev/null || echo "dmidecode not available"

# Check current boot device
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E "mmcblk|nvme|sda|sdb"
```

# Ugreen DXP2800 SSH Troubleshooting

## Current Status

- **IP**: 192.168.0.158
- **Username**: Pete
- **Port**: 22
- **SSH Status**: Enabled (per web UI)
- **Issue**: SSH not accepting password authentication

## Possible Causes

1. **SSH configured for key-only authentication**
   - Check UGOS web UI → Control Panel → Terminal → SSH settings
   - May need to enable password authentication

2. **SSH key already configured**
   - Check if your Mac's SSH key is already authorized
   - Try: `ssh -v Pete@192.168.0.158` to see what's happening

3. **Different authentication method**
   - UGOS might use a different auth method
   - Check web UI for SSH configuration options

## Manual Testing

Try connecting manually and observe what happens:

```bash
ssh Pete@192.168.0.158
```

**What to check:**
- Does it prompt for password?
- Does it connect without password?
- What error message appears?

## Next Steps

1. **Check UGOS Web UI SSH Settings**
   - Navigate to: Control Panel → Terminal
   - Verify SSH Service is enabled
   - Check authentication method (password vs key-only)
   - Look for any additional SSH configuration options

2. **Try Adding SSH Key Manually**
   ```bash
   # On your Mac
   cat ~/.ssh/id_ed25519.pub
   
   # Copy the output, then on UGOS web UI or via another method:
   # Add to ~/.ssh/authorized_keys
   ```

3. **Alternative: Use Web UI Terminal**
   - Some NAS systems have a web-based terminal
   - Check if UGOS has a terminal feature in the web UI
   - This might allow running commands without SSH

## Commands to Run Once Connected

Once SSH is working, run these to gather system info:

```bash
# System info
uname -a
cat /etc/os-release

# Disks
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
ls -la /dev/mmcblk* /dev/nvme* /dev/sd* 2>/dev/null

# Network
ip addr show
lspci | grep -iE 'nvme|network|ethernet'

# Storage
df -h
```

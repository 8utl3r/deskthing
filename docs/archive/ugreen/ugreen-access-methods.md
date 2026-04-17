# Ugreen DXP2800 Access Methods

## Current Situation

- **SSH**: Enabled but password authentication not working
- **Telnet**: Not available (port 23 closed)
- **Web UI**: Accessible at `http://192.168.0.158`

## Access Options

### Option 1: Fix SSH Password Authentication (Best)

**Steps:**
1. Access web UI: `http://192.168.0.158`
2. Navigate to: **Control Panel → Terminal → SSH Service**
3. Look for "Password authentication" or "Authentication method"
4. Enable password authentication
5. Save settings

**Why this is best:**
- ✅ Secure (encrypted)
- ✅ Full terminal access
- ✅ Can run all commands needed
- ✅ Standard method for NAS management

### Option 2: Web-Based Terminal (If Available)

Some NAS systems have a built-in web terminal. Check:

1. **Control Panel → Terminal**
2. Look for "Web Terminal" or "Console" option
3. If available, use it to run commands directly

**Commands to run:**
```bash
uname -a
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
ip addr show
df -h
ls -la /dev/mmcblk* /dev/nvme* /dev/sd* 2>/dev/null
```

### Option 3: Add SSH Key via Web UI

1. **Get your public key:**
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

2. **In UGOS web UI:**
   - Control Panel → Terminal → SSH Keys
   - Or User Settings → SSH Keys
   - Add the public key

3. **Then connect:**
   ```bash
   ssh Pete@192.168.0.158
   ```

### Option 4: Enable Telnet (Not Recommended)

**Security Warning:** Telnet sends passwords in plaintext!

If you really want to try:
1. Web UI → Control Panel → Terminal
2. Enable Telnet service
3. Connect: `telnet 192.168.0.158` (need to install telnet client first)

**Why not recommended:**
- ❌ Insecure (plaintext)
- ❌ Less feature-rich than SSH
- ❌ Still need to enable it in web UI anyway

## Recommended Next Steps

1. **Check web UI for password authentication setting**
   - This is the most important step
   - Look carefully in SSH/Terminal settings

2. **If password auth option exists, enable it**

3. **If no password auth option, try SSH key management**

4. **If web terminal exists, use that temporarily**

5. **Once access works, gather system info for TrueNAS prep**

## What We Need to Gather

Once we have terminal access (via any method), we need:

```bash
# System info
uname -a
cat /etc/os-release

# Disk layout (critical for TrueNAS planning)
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE

# Network interfaces
ip addr show
lspci | grep -iE 'nvme|network|ethernet|intel'

# Storage usage
df -h

# Device files
ls -la /dev/mmcblk* 2>/dev/null  # eMMC (boot device)
ls -la /dev/nvme* 2>/dev/null     # NVMe slots
ls -la /dev/sd* 2>/dev/null      # SATA drives
```

This information will help us:
- Plan TrueNAS installation (which drive to use)
- Backup UGOS firmware
- Understand hardware configuration

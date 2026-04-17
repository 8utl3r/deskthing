# Ugreen DXP2800 SSH Configuration

## Current SSH Settings (from Web UI)

- **Encryption algorithm**: Middle
- **Access restriction**: Local network access only ✅
- **SFTP**: Enabled ✅
- **Authentication method**: (Not visible - need to check)

## Issue

SSH connection negotiates successfully but authentication fails with:
```
Permission denied (publickey,password)
```

This suggests password authentication might be disabled.

## Solution Steps

### Option 1: Enable Password Authentication (Recommended)

1. **Access Web UI**: `http://192.168.0.158`
2. **Navigate to**: Control Panel → Terminal → SSH Service
3. **Look for**:
   - "Password authentication" option
   - "Authentication method" dropdown
   - "Allow password login" checkbox
4. **Enable password authentication**
5. **Save settings**

### Option 2: Add SSH Key via Web UI

1. **Check if web UI has SSH key management**:
   - Control Panel → Terminal → SSH Keys
   - Or User Settings → SSH Keys
   - Or System Settings → SSH

2. **Add your public key**:
   ```bash
   # On your Mac, get your public key:
   cat ~/.ssh/id_ed25519.pub
   ```
   
3. **Copy the output and paste into web UI SSH key field**

### Option 3: Use SFTP to Add Key

Since SFTP is enabled, we might be able to add the key via SFTP:

```bash
# Try SFTP connection
sftp Pete@192.168.0.158

# If that works, navigate to .ssh directory
cd .ssh
put ~/.ssh/id_ed25519.pub authorized_keys
```

## Testing After Configuration

Once password auth is enabled or key is added:

```bash
# Test connection
ssh Pete@192.168.0.158 "uname -a"

# If password auth works, gather system info
ssh Pete@192.168.0.158 << 'EOF'
uname -a
lsblk
ip addr show
df -h
EOF
```

## Next Steps

1. Check web UI for password authentication setting
2. Enable password authentication if available
3. Or add SSH key via web UI
4. Test SSH connection
5. Gather system information for TrueNAS preparation

# n8n Troubleshooting - TrueNAS Scale 25.04

## Current Situation

**What You See:**
- Storage Configuration shows only Host Path fields:
  - Data Storage: `/mnt/tank/apps/n8n`
  - Postgres Data Storage: `/mnt/tank/apps/n8n-postgres`

**What's Happening:**
- App state: STOPPED
- n8n container: Not running
- Web UI: Not accessible

---

## Understanding TrueNAS Apps

**TrueNAS Apps use templates** that define:
- Container images
- Mount paths (set automatically)
- Environment variables
- Port mappings

**You configure:**
- Host Paths (where data lives on TrueNAS)
- Port numbers
- Environment variables (if exposed)

**The app template handles:**
- Container mount paths (like `/home/node/.n8n` or `/data`)
- Container configuration
- Service dependencies

---

## Why n8n Might Not Be Starting

### Possible Issues:

1. **Mount Path Mismatch**
   - Template might mount to `/data` but n8n expects `/home/node/.n8n`
   - Or template uses environment variable `N8N_USER_FOLDER`

2. **Permissions Issue**
   - Directory owned by root, but container runs as user 568
   - Need to fix ownership

3. **Configuration Error**
   - Missing required environment variables
   - Database connection issue

4. **Container Startup Error**
   - Check container logs for specific error

---

## Next Steps to Diagnose

### 1. Check App Logs

**In TrueNAS Web UI:**
- Apps → Installed Apps → n8n
- Click on the app name or logs icon
- Look for error messages

### 2. Check Container Status

**Via SSH:**
```bash
ssh truenas_admin@192.168.0.158
# Check what containers exist
docker ps -a | grep n8n
```

### 3. Fix Permissions (If Needed)

**If n8n directory is owned by root:**
```bash
# In TrueNAS Shell (System Settings → Shell)
chown -R 568:568 /mnt/tank/apps/n8n
chmod 755 /mnt/tank/apps/n8n
```

### 4. Check App Configuration

**Look for:**
- Environment variables section
- Advanced settings
- Any errors shown in the UI

---

## What to Check in Web UI

1. **Apps → Installed Apps → n8n**
   - What does the status show?
   - Any error messages?
   - Click on the app to see details

2. **Check Logs**
   - Look for "Logs" or "View Logs" button
   - Check for permission errors, mount errors, startup errors

3. **Try Starting the App**
   - If it's stopped, try clicking "Start" or "Restart"
   - Watch for error messages

---

## Quick Fixes to Try

### Fix 1: Set Permissions
```bash
# In TrueNAS Shell
chown -R 568:568 /mnt/tank/apps/n8n
chmod 755 /mnt/tank/apps/n8n
```

### Fix 2: Check if App Needs Restart
- In Web UI, try stopping and starting the app
- Sometimes apps need a restart after configuration changes

### Fix 3: Check Environment Variables
- Look for "Environment" or "Advanced" section
- See if `N8N_USER_FOLDER` is set
- If mount is to `/data`, might need to set `N8N_USER_FOLDER=/data`

---

**What do you see when you click on the n8n app in the Installed Apps list? Any error messages or status details?**

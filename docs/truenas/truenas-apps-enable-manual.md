# Enable TrueNAS Apps - Manual Steps

## Current Status

✅ **Storage Pool Created:** `tank` (Mirror RAID1, ~1.76TB usable)  
✅ **Datasets Created:** media, apps, backups, documents  
❌ **Apps Not Enabled:** k3s/Kubernetes not running yet

## Why Manual Steps?

The TrueNAS Scale 25.04 API doesn't expose the Apps/Kubernetes configuration methods via `midclt`. The Apps system must be enabled through the web UI.

## Steps to Enable Apps

1. **Log into TrueNAS Web UI**
   - URL: `http://192.168.0.158`
   - Username: `truenas_admin`
   - Password: `12345678`

2. **Navigate to Apps Settings**
   - Click **Apps** in left sidebar
   - Click **Settings** (gear icon or Settings tab)

3. **Configure Apps Pool**
   - Find **"Pool"** or **"Select Pool"** dropdown
   - Select: **`tank`**
   - Click **"Choose Pool"** or **"Save"**

4. **Wait for Initialization**
   - k3s will start automatically
   - This may take 2-5 minutes
   - You'll see progress indicators

5. **Verify Apps are Enabled**
   - Go to **Apps → Available Apps**
   - Should see app catalog loading
   - Or check: **Apps → Installed Apps**

## After Apps are Enabled

Once Apps are enabled, I can:
- Install n8n via CLI
- Set up other apps
- Configure app storage mounts
- Manage everything via SSH

## Quick Verification Command

After enabling Apps, run this to verify:
```bash
ssh truenas_admin@192.168.0.158 "systemctl status k3s | head -5"
```

Should show k3s service running.

---

**Once you've enabled Apps, let me know and I'll continue with n8n installation!**

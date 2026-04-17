# Fix n8n Permissions - Quick Guide

## The Problem

**n8n directory is owned by root:**
```
drwxr-xr-x 2 root root /mnt/tank/apps/n8n
```

**But n8n container runs as user 568:568**

**Result:** Container can't write to the directory, so it exits/stops.

---

## The Fix

**Set correct ownership for n8n directory:**

### Option 1: Via TrueNAS Shell (Easiest)

1. **Open TrueNAS Web UI**
2. **Go to:** System Settings → **Shell**
3. **Run:**
   ```bash
   chown -R 568:568 /mnt/tank/apps/n8n
   chmod 755 /mnt/tank/apps/n8n
   ```
4. **Verify:**
   ```bash
   ls -ld /mnt/tank/apps/n8n
   ```
   Should show: `drwxr-xr-x 568 568`

5. **Start the app:**
   - Go to Apps → Installed Apps → n8n
   - Click "Start" or "Restart"

### Option 2: Via SSH

```bash
ssh truenas_admin@192.168.0.158
# Then in TrueNAS shell:
chown -R 568:568 /mnt/tank/apps/n8n
chmod 755 /mnt/tank/apps/n8n
```

---

## Why This Works

- **User 568** = n8n user (from app metadata)
- **Group 568** = n8n group
- **755 permissions** = Owner can read/write/execute, others can read/execute

---

## After Fixing Permissions

1. **Start the app** in Web UI
2. **Check if it stays running**
3. **Access Web UI** at `http://192.168.0.158:30109`

---

**Try this fix and let me know if n8n starts successfully!**

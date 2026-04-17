# Setting Directory Permissions in TrueNAS Scale

## The Problem

TrueNAS Web UI shows **datasets**, not regular directories. Directories inside datasets (like `n8n-postgres`) aren't visible in the dataset browser.

## Solution: Use TrueNAS Shell

### Option 1: Web UI Shell (Easiest)

1. **Open TrueNAS Web UI**
2. **Go to:** System Settings → Shell (or click the Shell icon in top bar)
3. **Run these commands:**
   ```bash
   chown -R 999:999 /mnt/tank/apps/n8n-postgres
   chmod 0700 /mnt/tank/apps/n8n-postgres
   ```
4. **Verify:**
   ```bash
   ls -ld /mnt/tank/apps/n8n-postgres
   ```
   Should show: `drwx------ 999 999`

### Option 2: SSH Shell

If you have SSH access:
```bash
ssh truenas_admin@192.168.0.158
# Then run:
chown -R 999:999 /mnt/tank/apps/n8n-postgres
chmod 0700 /mnt/tank/apps/n8n-postgres
ls -ld /mnt/tank/apps/n8n-postgres
```

### Option 3: Let PostgreSQL Handle It (Simplest!)

**Actually, PostgreSQL containers often handle permissions automatically!**

If the directory exists but has wrong permissions, PostgreSQL will often:
- Fix permissions on first startup
- Create necessary files with correct ownership

**You can try:**
1. Just use `/mnt/tank/apps/n8n-postgres` in the storage config
2. Let PostgreSQL container start
3. If it fails with permission errors, then use Option 1 or 2 above

---

## Why This Happens

- **Datasets** = ZFS filesystems (shown in Web UI)
- **Directories** = Regular folders inside datasets (not shown in Web UI)
- Web UI focuses on dataset-level management, not file-level

## Recommended Approach

**For PostgreSQL:**
- Try letting the container handle permissions first (Option 3)
- If that fails, use Web UI Shell (Option 1)

**For n8n app data:**
- Standard permissions (755) are usually fine
- No special setup needed

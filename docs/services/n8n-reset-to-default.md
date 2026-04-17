# Reset n8n to Default (Fresh Start)

## Steps to Reset n8n

Since you haven't created any workflows, we can delete all data and start fresh.

### Step 1: Stop n8n App

1. **Go to:** TrueNAS Web UI → Apps → Installed Apps → n8n
2. **Click:** Stop (if running)

### Step 2: Delete Data Directories

**In TrueNAS Shell (System Settings → Shell):**

```bash
# Delete n8n app data (workflows, credentials, settings)
rm -rf /mnt/tank/apps/n8n/*

# Delete PostgreSQL database (all data)
rm -rf /mnt/tank/apps/n8n-postgres/*

# Verify directories are empty
ls -la /mnt/tank/apps/n8n
ls -la /mnt/tank/apps/n8n-postgres
```

### Step 3: Restart n8n App

1. **Go to:** Apps → Installed Apps → n8n
2. **Click:** Start (or Restart)

### Step 4: Access n8n

1. **Wait 2-3 minutes** for initialization
2. **Visit:** `https://n8n.xcvr.link` (or `http://192.168.0.158:30109`)
3. **You should see:** Setup form to create admin account
4. **Create new admin credentials**

## What Gets Deleted

- ✅ All workflows (none exist anyway)
- ✅ All credentials
- ✅ All execution history
- ✅ All settings
- ✅ Database (PostgreSQL will recreate it)

## What Stays

- ✅ App configuration (ports, storage mounts, etc.)
- ✅ Environment variables
- ✅ Storage directories (just emptied, not deleted)

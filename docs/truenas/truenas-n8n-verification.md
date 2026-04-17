# n8n Installation Verification

## Current Status

### ✅ Working Components

1. **App State:** RUNNING (but n8n container exited)
2. **PostgreSQL Container:** ✅ Running
   - Storage: `/mnt/tank/apps/n8n-postgres` → `/var/lib/postgresql`
   - Permissions: Correct (netdata:docker = 999:999)
   - Data: Present (PostgreSQL initialized)

3. **Redis Container:** ✅ Running
   - Storage: Using ixVolume (managed)

### ⚠️ Issues Found

1. **n8n Container:** ❌ Exited (not running)
   - Container ID: `b9a224a54dbd2d9c823e71bcaf18420cafb910d739d8e06310c5a8beb5802a24`
   - State: `exited`
   - **Problem:** Storage mount may be incorrect

2. **Storage Mount Issue:**
   - Current mount: `/mnt/tank/apps/n8n` → `/data`
   - **Expected:** `/mnt/tank/apps/n8n` → `/home/node/.n8n`
   - n8n expects data directory at `/home/node/.n8n`, not `/data`

3. **Web UI Not Accessible:**
   - Port: 30109
   - Status: Connection failed
   - Reason: n8n container not running

---

## Storage Configuration Check

**Current Mounts:**
- n8n: `/mnt/tank/apps/n8n` → `/data` ⚠️ (should be `/home/node/.n8n`)
- PostgreSQL: `/mnt/tank/apps/n8n-postgres` → `/var/lib/postgresql` ✅
- Redis: Using ixVolume ✅

---

## Next Steps

### Option 1: Fix Storage Mount (Recommended)

The n8n container needs its data directory mounted to `/home/node/.n8n`, not `/data`.

**In TrueNAS Web UI:**
1. Go to **Apps** → **Installed Apps** → **n8n**
2. Click **Edit** (or three dots → Edit)
3. Find **Storage** section
4. Look for n8n app storage mount
5. Change **Container Path** from `/data` to `/home/node/.n8n`
6. Save and restart

### Option 2: Check Container Logs

**Via Web UI:**
1. Go to **Apps** → **Installed Apps** → **n8n**
2. Click on the container name or logs icon
3. Check for error messages

**Via SSH (if you have shell access):**
```bash
ssh truenas_admin@192.168.0.158
# Then check logs (may need root):
docker logs b9a224a54dbd2d9c823e71bcaf18420cafb910d739d8e06310c5a8beb5802a24
```

---

## Verification Checklist

- [ ] PostgreSQL container running ✅
- [ ] Redis container running ✅
- [ ] n8n container running ❌ (exited)
- [ ] Storage mounts correct ⚠️ (n8n mount path wrong)
- [ ] Web UI accessible ❌ (container not running)
- [ ] Data directories have correct permissions ✅

---

## Summary

**What's Working:**
- PostgreSQL is running and has correct permissions
- Redis is running
- Storage directories exist

**What Needs Fixing:**
- n8n container storage mount path (should be `/home/node/.n8n` not `/data`)
- n8n container needs to be restarted after fixing mount

**Action Required:**
Edit the n8n app configuration to change the container path from `/data` to `/home/node/.n8n`.

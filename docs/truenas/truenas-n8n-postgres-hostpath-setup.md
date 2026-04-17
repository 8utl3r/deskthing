# PostgreSQL Host Path Setup for n8n

## Overview

PostgreSQL requires strict permissions when using Host Path storage:
- **Owner:** 999:999 (postgres user/group)
- **Permissions:** 0700 (owner read/write/execute only)
- **ACL Type:** POSIX (not NFSv4)

---

## Setup Steps

### 1. Directory Created ✅

The PostgreSQL data directory has been created:
- **Path:** `/mnt/tank/apps/n8n-postgres`
- **Container Path:** `/var/lib/postgresql/data`

### 2. Set Permissions ⚠️

**The directory exists, but you can't see it in the Web UI** (Web UI only shows datasets, not directories).

**Option A: Use TrueNAS Shell (Recommended)**

1. **Open TrueNAS Web UI**
2. **Go to:** System Settings → **Shell** (or Shell icon in top bar)
3. **Run:**
   ```bash
   chown -R 999:999 /mnt/tank/apps/n8n-postgres
   chmod 0700 /mnt/tank/apps/n8n-postgres
   ```
4. **Verify:**
   ```bash
   ls -ld /mnt/tank/apps/n8n-postgres
   ```
   Should show: `drwx------ 999 999`

**Option B: Let PostgreSQL Handle It (Try This First!)**

PostgreSQL containers often fix permissions automatically on first startup. You can:
1. Configure storage in n8n wizard with `/mnt/tank/apps/n8n-postgres`
2. Start the app
3. If it fails with permission errors, use Option A above

### 3. Verify Permissions

After setting permissions, verify:
```bash
ssh truenas_admin@192.168.0.158 "ls -ld /mnt/tank/apps/n8n-postgres"
```

Should show:
```
drwx------  999 999  /mnt/tank/apps/n8n-postgres
```

---

## Configuration in n8n Wizard

### Storage Section

When configuring storage in the n8n installation wizard:

**PostgreSQL Storage:**
- **Storage Type:** Host Path
- **Host Path:** `/mnt/tank/apps/n8n-postgres`
- **Container Path:** `/var/lib/postgresql/data`
- **Read Only:** No (unchecked)

**n8n App Storage:**
- **Storage Type:** Host Path
- **Host Path:** `/mnt/tank/apps/n8n`
- **Container Path:** `/home/node/.n8n`
- **Read Only:** No (unchecked)

**Redis Storage (if separate):**
- **Storage Type:** Host Path
- **Host Path:** `/mnt/tank/apps/n8n-redis` (create if needed)
- **Container Path:** `/data` (or `/var/lib/redis`)
- **Read Only:** No (unchecked)

---

## Why These Permissions?

**PostgreSQL Security:**
- PostgreSQL requires the data directory to be owned by the postgres user (UID 999)
- Permissions must be 0700 to prevent other users from accessing database files
- This is a PostgreSQL security requirement, not just TrueNAS

**POSIX vs NFSv4 ACL:**
- POSIX ACLs work correctly with Docker containers
- NFSv4 ACLs (used for SMB shares) can confuse Docker
- PostgreSQL containers expect standard Unix permissions

---

## Troubleshooting

### If PostgreSQL Container Fails to Start

**Error:** `"data directory has invalid permissions"` or `"wrong ownership"`

**Fix via Web UI:**
1. Go to **Storage** → **Datasets** → `tank/apps`
2. Find `n8n-postgres` folder
3. Click **Edit Permissions**
4. Set User: `999`, Group: `999`, Mode: `0700`
5. Check **Apply recursively**

**Fix via Shell (if you have root/SSH shell access):**
```bash
# SSH into TrueNAS and use shell (not midclt):
chown -R 999:999 /mnt/tank/apps/n8n-postgres
chmod 0700 /mnt/tank/apps/n8n-postgres
```

### If Dataset Uses NFSv4 ACL

**Check ACL type:**
```bash
ssh truenas_admin@192.168.0.158 "midclt call pool.dataset.query | jq -r '.[] | select(.name == \"tank/apps\") | .acltype.value'"
```

**Should be:** `POSIX`

**If NFSv4:** Create a sub-dataset with POSIX ACL:
- In Web UI: Datasets → Add Dataset
- Name: `n8n-postgres`
- ACL Type: `POSIX`
- Use this dataset instead

---

## Summary

✅ **PostgreSQL directory:** `/mnt/tank/apps/n8n-postgres` (created)
⚠️ **Permissions:** Need to set via Web UI (User: 999, Group: 999, Mode: 0700)
✅ **Ready for:** Container path `/var/lib/postgresql/data`

**Next Steps:**
1. Set permissions via Web UI (see Step 2 above)
2. Configure storage in n8n installation wizard:
   - Host Path: `/mnt/tank/apps/n8n-postgres`
   - Container Path: `/var/lib/postgresql/data`

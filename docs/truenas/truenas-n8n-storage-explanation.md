# n8n Storage Configuration Explained

## Storage Types in TrueNAS Apps

### ixVolume (Internal/Managed Storage)
**What it is:**
- TrueNAS-managed storage created automatically
- Stored in `/mnt/[pool]/.ix-applications/`
- Managed by Kubernetes/Docker system
- **Not directly accessible** via SMB/NFS/shell

**Pros:**
- ✅ Automatic permission management
- ✅ Works seamlessly with app updates
- ✅ Less likely to break on updates

**Cons:**
- ❌ Harder to access data directly
- ❌ More difficult to backup manually
- ❌ Can't easily browse files

### Host Path (Manual Dataset)
**What it is:**
- Maps directly to a ZFS dataset you create
- Full access via SMB/NFS/shell
- You manage permissions manually

**Pros:**
- ✅ Easy to access/backup data
- ✅ Can browse files directly
- ✅ Better for migrations

**Cons:**
- ❌ Requires manual permission setup
- ❌ Can break if permissions wrong
- ❌ More setup work

---

## Why Host Path for n8n?

**For n8n workflows:**
- You'll want to backup workflows
- May want to access files directly
- Easier to migrate/restore

**For PostgreSQL/Redis:**
- Usually better with ixVolume (managed)
- Less likely to have permission issues
- System handles it automatically

---

## n8n App Storage Requirements

The n8n app likely includes **3 containers**:
1. **n8n** (main app)
2. **PostgreSQL** (database)
3. **Redis** (cache/queue)

**Each needs storage:**

### 1. n8n App Data
- **Container Path:** `/home/node/.n8n`
- **Host Path:** `/mnt/tank/apps/n8n`
- **What it stores:** Workflows, credentials, settings
- **Use:** Host Path (for easy access/backup)

### 2. PostgreSQL Data
- **Container Path:** `/var/lib/postgresql/data`
- **What it stores:** Database files (workflows, executions)
- **Use:** ixVolume (recommended) OR Host Path
- **If Host Path:** Need ACL enabled, permissions 0700, owner 999:999

### 3. Redis Data
- **Container Path:** `/data` (or `/var/lib/redis`)
- **What it stores:** Cache/queue data
- **Use:** ixVolume (usually fine) OR Host Path

---

## ACL (Access Control Lists)

**Do you need ACL?**

**For n8n app data (`/home/node/.n8n`):**
- ❌ **No ACL needed** - Standard POSIX permissions work fine
- Use regular dataset permissions

**For PostgreSQL (`/var/lib/postgresql/data`):**
- ✅ **ACL recommended** if using Host Path
- PostgreSQL is very sensitive to permissions
- ACL gives finer control

**How to enable ACL:**
- In dataset properties: `ACL Type` → `POSIX` or `NFSv4`
- Or leave as default (POSIX usually works)

---

## Recommended Configuration

### Option 1: Mixed Approach (Recommended)

**n8n App Data:**
- Use **Host Path**: `/mnt/tank/apps/n8n` → `/home/node/.n8n`
- ACL: Not needed (standard permissions OK)
- Easy to backup/access workflows

**PostgreSQL Data:**
- Use **ixVolume** (if available)
- Let TrueNAS manage it
- Less permission headaches

**Redis Data:**
- Use **ixVolume** (if available)
- Usually doesn't need manual access

### Option 2: All Host Path (More Control)

**If you want full control:**
- n8n: Host Path `/mnt/tank/apps/n8n`
- PostgreSQL: Host Path `/mnt/tank/apps/n8n-postgres` (with ACL)
- Redis: Host Path `/mnt/tank/apps/n8n-redis`

**PostgreSQL Host Path Requirements:**
- ACL: Enable POSIX ACL
- Permissions: 0700 (owner only)
- Owner: 999:999 (postgres user)
- Path: `/mnt/tank/apps/n8n-postgres`

---

## What You're Seeing in the Wizard

**"Container Path"** = Path inside the Docker container
- `/home/node/.n8n` = Where n8n stores data inside container
- `/var/lib/postgresql/data` = Where PostgreSQL stores DB files

**"Host Path"** = Path on TrueNAS filesystem
- `/mnt/tank/apps/n8n` = Your dataset on TrueNAS
- Maps container path to your dataset

**ixVolume** = TrueNAS creates/manages storage automatically
- You don't specify a path
- System handles it
- Less control, more automation

---

## My Recommendation

**For your setup:**

1. **n8n App Data:** Use Host Path
   - Path: `/mnt/tank/apps/n8n` → `/home/node/.n8n`
   - ACL: Not needed
   - Easy to backup workflows

2. **PostgreSQL:** Use ixVolume (if option available)
   - Let TrueNAS manage it
   - Less permission issues
   - If only Host Path available, enable ACL

3. **Redis:** Use ixVolume (if available)
   - Usually doesn't need manual access

**If only Host Path options available:**
- Use Host Path for all
- Enable ACL on PostgreSQL dataset
- Set proper permissions

---

**What storage options do you see in the wizard? Are there separate sections for PostgreSQL and Redis, or just one storage section?**

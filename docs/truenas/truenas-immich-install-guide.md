# Immich Installation on TrueNAS Scale

## Overview

Immich is available in the **community train** on TrueNAS Scale. It's a self-hosted photo management app with AI features (face recognition, object detection).

## Prerequisites

✅ Storage directories created:
- `/mnt/tank/apps/immich` - Immich configuration
- `/mnt/tank/apps/immich/library` - Photo library storage
- `/mnt/tank/apps/immich/postgres` - PostgreSQL database (owned by 999:999)
- `/mnt/tank/apps/immich/redis` - Redis cache

✅ Permissions set:
- Immich directories: `apps:apps` (568:568)
- PostgreSQL directory: `netdata:docker` (999:999)

## Installation Steps

### Option 1: Via App Catalog (Recommended)

1. **Open TrueNAS Web UI**
   - Go to `http://192.168.0.158`
   - Navigate to **Apps** → **Discover Apps**

2. **Switch to Community Train**
   - Look for train/catalog filter (top of page)
   - Change from "stable" to **"community"**
   - Or look for tabs: "Stable", "Community"

3. **Search for Immich**
   - Search: `immich`
   - Should appear in results

4. **Install Immich**
   - Click **Install** or **Deploy**
   - Follow installation wizard

5. **Configure Storage**
   - **Library/Upload Location:** `/mnt/tank/apps/immich/library`
   - **PostgreSQL Data:** `/mnt/tank/apps/immich/postgres`
   - **Redis Data:** `/mnt/tank/apps/immich/redis` (optional)

6. **Configure Port**
   - Default: `30041` (or custom port - check your installation)
   - Access at: `http://192.168.0.158:30041`

7. **Set Environment Variables**
   - `TZ`: Your timezone (e.g., `America/Los_Angeles`)
   - `DB_PASSWORD`: Strong password (alphanumeric only: A-Za-z0-9)
   - Other variables as needed

8. **Deploy**
   - Review configuration
   - Deploy the app
   - Wait for initialization (2-5 minutes)

### Option 2: Custom Docker Compose (If Catalog Doesn't Work)

If Immich isn't available in the catalog, install as custom app:

1. **Apps** → **Discover Apps** → Three dots (⋮) → **Install via YAML**

2. **Use Docker Compose YAML** (see below)

---

## Storage Configuration

**Required Mounts:**

1. **Library/Upload Location:**
   - Host Path: `/mnt/tank/apps/immich/library`
   - Container Path: `/usr/src/app/upload` (or as configured)
   - Purpose: Stores all photos/videos

2. **PostgreSQL Data:**
   - Host Path: `/mnt/tank/apps/immich/postgres`
   - Container Path: `/var/lib/postgresql/data`
   - Owner: 999:999 (postgres user)
   - **Critical:** Must be owned by postgres user

3. **Redis Data (Optional):**
   - Host Path: `/mnt/tank/apps/immich/redis`
   - Container Path: `/data`
   - Purpose: Cache and task queue

---

## Environment Variables

**Required:**
- `UPLOAD_LOCATION`: `/usr/src/app/upload` (or container path)
- `DB_DATA_LOCATION`: `/var/lib/postgresql/data` (or container path)
- `TZ`: Your timezone (e.g., `America/Los_Angeles`)
- `DB_PASSWORD`: Database password (**alphanumeric only**: A-Za-z0-9)

**Important Notes:**
- `DB_PASSWORD` must be alphanumeric only (no special characters)
- Use strong passwords but avoid special chars in DB password
- Timezone affects metadata and log timestamps

---

## Upgrading

**Before upgrading:** Back up the database (see [Immich backup/restore](https://immich.app/administration/backup-and-restore)). Check [release notes](https://github.com/immich-app/immich/releases) and [breaking changes](https://github.com/immich-app/immich/discussions?discussions_q=label:changelog:breaking-change+sort:date_created).

### If installed via App Catalog

1. **Apps** → **Installed Applications** → find **Immich**
2. Use **Update** / **Upgrade** when the catalog offers a new version
3. Redeploy and wait for containers to come up

### If installed via Docker Compose (custom YAML)

1. Update `IMMICH_VERSION` in your env (or the image tag in the compose YAML) to the desired version
2. In the directory with `docker-compose.yml`:  
   `docker compose pull && docker compose up -d`
3. Optional cleanup: `docker image prune`

**Note:** If you're on a version older than v1.132.0, upgrade to v1.136.0 first, then to the latest (v1.137+ has breaking DB schema changes).

---

## Post-Installation

1. **Access Immich Web UI**
   - Open `http://192.168.0.158:30041` (or check your actual port)
   - Create admin account (first user is admin)

2. **Upload Photos**
   - Use web interface or mobile app
   - Photos stored in `/mnt/tank/apps/immich/library`

3. **Configure AI Features**
   - Face recognition (automatic)
   - Object detection (automatic)
   - Smart albums

4. **Install Mobile App**
   - Download Immich app for iOS/Android
   - Connect to `http://192.168.0.158:30041` (or your actual port)
   - Enable auto-backup

---

## Permissions Verification

**Check permissions after installation:**

```bash
# Library should be apps:apps (568:568)
ls -ld /mnt/tank/apps/immich/library

# PostgreSQL should be netdata:docker (999:999)
ls -ld /mnt/tank/apps/immich/postgres
```

**If wrong, fix:**
```bash
# Via TrueNAS Shell
chown -R 568:568 /mnt/tank/apps/immich/library
chown -R 999:999 /mnt/tank/apps/immich/postgres
```

---

## Troubleshooting

### Container Won't Start
- Check PostgreSQL directory permissions (must be 999:999)
- Verify storage paths exist
- Check logs in TrueNAS Apps → Installed Apps → immich

### Database Connection Errors
- Verify `DB_PASSWORD` is alphanumeric only
- Check PostgreSQL container is running
- Verify PostgreSQL data directory permissions

### Can't Upload Photos
- Check library directory permissions (should be 568:568)
- Verify storage mount is correct
- Check available disk space

### AI Features Not Working
- Wait for initial indexing (can take time)
- Check container logs for errors
- Verify sufficient resources (CPU/RAM)

---

## Integration with Atlas AI

**For AI integration with your personal AI:**

1. **Export Photo Metadata**
   - Immich has API for accessing photos
   - Can index photo descriptions, locations, faces

2. **Index Photo Descriptions**
   - Use Immich API to get photo metadata
   - Index descriptions in Qdrant for Atlas

3. **Query Photos via Atlas**
   - "Show me photos from last summer"
   - "Find photos with my dog"
   - "Photos taken in San Francisco"

**Future:** Can set up Atlas proxy to query Immich API and index photo metadata.

---

## Next Steps

1. ✅ Install Immich via App Catalog
2. ✅ Configure storage mounts
3. ✅ Set environment variables
4. ✅ Access web UI and create admin account
5. ✅ Upload photos
6. ✅ Set up mobile app auto-backup
7. ✅ Configure AI integration (future)

---

**✅ Immich is installed and running!**
- **Access:** `http://192.168.0.158:30041` (check your actual port)
- **Status:** Running
- **Next:** Access web UI and create admin account

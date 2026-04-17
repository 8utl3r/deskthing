# TrueNAS Scale Setup Plan

## Current System State

**Hardware:**
- **OS Drive:** NVMe 931GB (boot-pool - TrueNAS installed here)
- **Data Drives:** 
  - sda: 2.7TB SATA drive
  - sdb: 1.8TB SATA drive
- **eMMC:** 29GB (UGOS - preserved for rollback)

**Software:**
- TrueNAS Scale 25.04.2.4
- k3s (Kubernetes) for containerization
- No storage pools created yet
- Apps system ready to use

---

## Recommended Setup Order

### Phase 1: Storage Foundation (Do First!)

**1. Create Storage Pool from SATA Drives**
- **Purpose:** Store media files, app data, backups
- **Drives:** Use both sda and sdb
- **Configuration Options:**
  - **Mirror (RAID1):** ~1.8TB usable, redundancy (recommended)
  - **Stripe (RAID0):** ~4.5TB usable, no redundancy (faster, riskier)
  - **Single drive:** Use larger drive (2.7TB), keep other as spare

**Recommendation:** **Mirror (RAID1)** for redundancy
- You have 2 different sized drives (2.7TB + 1.8TB)
- Mirror will use 1.8TB from each = 1.8TB usable
- Protects against drive failure
- Can add larger drives later and expand

**2. Create Datasets for Organization**
- `media/` - Movies, TV shows, music, photos
- `apps/` - App data (n8n, etc.)
- `backups/` - System backups
- `documents/` - Personal files
- `downloads/` - Temporary downloads

---

### Phase 2: Enable Apps (Container System)

**TrueNAS Scale uses k3s (Kubernetes), not Docker directly**

**1. Enable Apps Service**
- System → Apps → Settings
- Enable Apps (starts k3s)
- Configure pool for app data (use main pool)

**2. Add App Catalogs (Optional)**
- TrueCharts (community apps)
- Official catalog (already included)

---

### Phase 3: Install n8n

**Option A: Via App Catalog (Easiest)**
- Apps → Discover Apps
- Search "n8n"
- Install from catalog
- Configure storage mounts

**Option B: Custom App (More Control)**
- Apps → Custom App
- Use official n8n Docker image: `n8nio/n8n`
- Configure ports, storage, environment variables

**n8n Configuration:**
- Port: 5678 (default)
- Storage: Mount `apps/n8n` dataset
- Environment: Set `N8N_BASIC_AUTH_ACTIVE=true` for security

---

### Phase 4: Network Shares (Media Access)

**1. Create SMB Share for Media**
- Shares → SMB → Add
- Path: `/mnt/pool-name/media`
- Enable guest access (optional)
- Set permissions

**2. Create NFS Share (if needed)**
- For Linux/Mac access
- Shares → NFS → Add
- Configure exports

---

### Phase 5: Additional Apps (Future)

**Potential apps to install:**
- **Qdrant** - Vector database for Atlas RAG
- **Jellyfin/Plex** - Media server
- **Nextcloud** - File sync/sharing
- **Home Assistant** - Home automation
- **Portainer** - Container management UI

---

## Step-by-Step: Let's Start!

**Immediate next steps:**

1. **Create Storage Pool** (most important!)
   - Storage → Pools → Add
   - Select both sda and sdb
   - Choose Mirror (RAID1)
   - Name it: `tank` or `data-pool`

2. **Create Datasets**
   - After pool created
   - Add datasets: `media`, `apps`, `backups`

3. **Enable Apps**
   - System → Apps → Settings
   - Enable Apps
   - Select pool for app data

4. **Install n8n**
   - Apps → Discover Apps → n8n
   - Or Custom App with `n8nio/n8n`

---

## Important Notes

**TrueNAS Scale vs Docker:**
- ✅ Uses k3s (Kubernetes) - can run Docker containers
- ✅ Apps system wraps Docker images into Kubernetes pods
- ❌ No native `docker` command (use Apps or Custom App)
- ✅ Can use "Custom App" to run any Docker image

**Storage Recommendations:**
- Use Mirror (RAID1) for redundancy
- Create separate datasets for organization
- Apps need their own dataset/pool for data persistence

**n8n on TrueNAS:**
- Works great via Apps system
- Can mount storage for workflow persistence
- Access via web UI on port 5678

---

**Ready to start? Let's create the storage pool first!**

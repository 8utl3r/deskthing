# TrueNAS Apps Storage Field Names

## Storage Configuration Fields

In TrueNAS Scale 25.04 Apps, storage mounts use these field names:

### Field Names in Web UI

1. **Host Path** (or "Dataset Path")
   - The path on your TrueNAS filesystem
   - Example: `/mnt/tank/apps/n8n`

2. **Mount Path** (this is what you're looking for!)
   - The path **inside the container** where data will be accessible
   - This is what we called "Container Path" before
   - Example: `/home/node/.n8n`

3. **Storage Type** (or "Volume Type")
   - Options: `Host Path`, `ixVolume`, `PVC`
   - Select `Host Path` for manual dataset mounts

---

## What You Should See

When editing n8n storage, look for:

**Storage Configuration Section:**
- **Host Path:** `/mnt/tank/apps/n8n`
- **Mount Path:** `/data` ← **Change this to `/home/node/.n8n`**
- **Type:** Host Path
- **Read Only:** No (unchecked)

---

## Alternative Field Names

Depending on the app or TrueNAS version, you might see:
- **Mount Path** = Container path (most common)
- **Container Path** = Same thing
- **Destination Path** = Same thing
- **Volume Mount Path** = Same thing
- **Path** = Could be either host or container path (check context)

---

## For n8n Specifically

**n8n App Storage:**
- **Host Path:** `/mnt/tank/apps/n8n`
- **Mount Path:** `/home/node/.n8n` ← **This is what needs to change from `/data`**

**PostgreSQL Storage:**
- **Host Path:** `/mnt/tank/apps/n8n-postgres`
- **Mount Path:** `/var/lib/postgresql/data` (or `/var/lib/postgresql`)

---

## If You Can't Find "Mount Path"

**Look for:**
- Storage section with expandable rows
- Each storage mount might be in a table/list
- Click "Edit" or pencil icon on the storage entry
- Look for fields like "Path", "Destination", "Mount"

**Or check:**
- Advanced settings
- Storage tab
- Volumes section
- Resource configuration

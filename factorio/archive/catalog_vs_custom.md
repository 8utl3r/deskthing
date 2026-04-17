# Factorio: Catalog App vs Custom App

## Factorio in TrueNAS App Catalog

**Available:** Yes, in TrueNAS Apps Market (Community train)

**How to check:**
1. Go to **Apps** → **Discover Apps**
2. Look for **Train/Catalog filter** (may need to switch to "Community" train)
3. Search for "factorio"
4. Should appear as an installable app

## Comparison: Catalog vs Custom

### Catalog App (Easier)
**Pros:**
- ✅ One-click install
- ✅ Pre-configured settings
- ✅ Automatic updates via catalog
- ✅ Web UI configuration
- ✅ Less manual work

**Cons:**
- ⚠️ May not allow custom storage paths (might default to tank pool)
- ⚠️ May not expose all RCON settings
- ⚠️ May not allow resource limits customization
- ⚠️ Less control over exact configuration

### Custom App (More Control)
**Pros:**
- ✅ Full control over configuration
- ✅ Can use boot-pool (NVMe) for storage
- ✅ Custom resource limits (2GB RAM, 2 CPU cores)
- ✅ Exact RCON password control
- ✅ Custom healthcheck settings

**Cons:**
- ⚠️ More manual setup
- ⚠️ Need to manage updates manually
- ⚠️ More configuration to maintain

## Recommendation

**Try the catalog app first!**

1. **Check if Factorio is in the catalog:**
   - Apps → Discover Apps
   - Switch to "Community" train if needed
   - Search "factorio"

2. **If it's available:**
   - Install from catalog
   - Check if you can:
     - Set storage to `/mnt/boot-pool/apps/factorio`
     - Configure RCON password
     - Set resource limits
   - If all those work → use catalog app!
   - If not → use custom app

3. **If it's not available:**
   - Use custom app (our YAML)

## Quick Check

**In TrueNAS Web UI:**
- Apps → Discover Apps
- Look for train filter (Stable/Community/Enterprise)
- Search "factorio"
- If found → try installing and see if it meets your needs!
